#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <fluidsynth.h>
#include <err.h>
#include <stdint.h>
#include <unistd.h>
#include <errno.h>
#include <assert.h>

// #define DEBUG
#ifdef DEBUG
#define debug(msg, ...) fprintf(stderr, msg "\r\n", __VA_ARGS__)
#else
#define debug(msg, ...)
#endif

#if defined (__linux__)
#define OVERRIDE_AUDIO_DRIVER "pulseaudio"
#endif

enum midi_parser_state {
    STATE_IDLE = 0,
    STATE_TRIPLE1,  /* Waiting for parameter one of a 3-byte MIDI command */
    STATE_TRIPLE2,  /* Waiting for parameter two of a 3-byte MIDI command */
    STATE_DOUBLE1,  /* Waiting for parameter one of a 2-byte MIDI command */
    STATE_SYSEX,
    STATE_COUNT
};

struct midi_parser {
    uint8_t buffer[64];
    size_t offset;

    enum midi_parser_state state;

    void (*dispatch_cmd)(const uint8_t *message);

    int event_start_ix[STATE_COUNT + 1];
};

struct midi_event {
    enum midi_parser_state state;
    uint8_t mask;
    uint8_t value;
    enum midi_parser_state next_state;

    // Handle the event
    void (*handler)(uint8_t data, void *cookie);

    void *cookie;
};

static struct midi_parser parser;
static fluid_synth_t *synth = NULL;

static void dispatch_note_on(const uint8_t *buffer)
{
    debug("%d: note_on %d %d", buffer[0] & 0x0f, buffer[1], buffer[2]);
    fluid_synth_noteon(synth, buffer[0] & 0x0f, buffer[1], buffer[2]);
}
static void dispatch_note_off(const uint8_t *buffer)
{
    debug("%d: note_off %d", buffer[0] & 0x0f, buffer[1]);
    fluid_synth_noteoff(synth, buffer[0] & 0x0f, buffer[1]);
}
static void dispatch_aftertouch(const uint8_t *buffer)
{
    (void) buffer;
    debug("%d: aftertouch %d %d", buffer[0] & 0x0f, buffer[1], buffer[2]);
}
static void dispatch_control_change(const uint8_t *buffer)
{
    switch (buffer[1]) {
    case 0x00: // Bank select MSB
        debug("%d: bank select MSB", buffer[0] & 0x0f);
        fluid_synth_cc(synth, buffer[0] & 0x0f, buffer[1], buffer[2]);
        break;
    case 0x01: // Modulation wheel
        debug("%d: modulation wheel %d", buffer[0] & 0x0f, buffer[2]);
        break;
    case 0x07: // Channel Volume
        debug("%d: channel volume %d", buffer[0] & 0x0f, buffer[2]);
        fluid_synth_cc(synth, buffer[0] & 0x0f, buffer[1], buffer[2]);
        break;
    case 0x20: // Bank select LSB
        debug("%d: bank select LSB", buffer[0] & 0x0f);
        fluid_synth_cc(synth, buffer[0] & 0x0f, buffer[1], buffer[2]);
        break;
    case 0x79: // Reset all controllers
        debug("%d: fluid_synth_system_reset", buffer[0] & 0x0f);
        fluid_synth_system_reset(synth);
        break;
    case 0x7a: // Local control
        debug("%d: local control", buffer[0] & 0x0f);
        break;
    case 0x7b: // All notes off
        debug("%d: all notes off", buffer[0] & 0x0f);
        fluid_synth_all_notes_off(synth, buffer[0] & 0x0f);
        break;
    case 0x7c: // Omni mode off
        debug("%d: Omni mode off", buffer[0] & 0x0f);
        break;
    case 0x7d: // Omni mode on
        debug("%d: Omni mode on", buffer[0] & 0x0f);
        break;
    case 0x7e: // Mono mode on (Poly mode off)
        debug("%d: Mono mode on (Poly mode off)", buffer[0] & 0x0f);
        break;
    case 0x7f: // Poly mode on (Mono mode off)
        debug("%d: Poly mode on (Mono mode off)", buffer[0] & 0x0f);
        break;
    default:
        debug("%d: Unknown control change: %02x %02x", buffer[0] & 0x0f, buffer[1], buffer[2]);
        break;
    }
}
static void dispatch_program_change(const uint8_t *buffer)
{
    debug("%d: fluid_synth_program_change %d", buffer[0] & 0x0f, buffer[1]);
    fluid_synth_program_change(synth, buffer[0] & 0x0f, buffer[1]);
}
static void dispatch_channel_pressure(const uint8_t *buffer)
{
    debug("%d: fluid_synth_channel_pressure %d", buffer[0] & 0x0f, buffer[1]);
    fluid_synth_channel_pressure(synth, buffer[0] & 0x0f, buffer[1]);
}
static void dispatch_pitch_wheel(const uint8_t *buffer)
{
    debug("%d: fluid_synth_pitch_bend %d (%02x %02x)", buffer[0] & 0x0f, (buffer[2] << 7) | buffer[1], buffer[1], buffer[2]);
    fluid_synth_pitch_bend(synth, buffer[0] & 0x0f, (buffer[2] << 7) | buffer[1]);
}

static void handle_start(uint8_t data, void *cookie)
{
    parser.buffer[0] = data;
    parser.dispatch_cmd = cookie;
}

static void handle_save_param1(uint8_t data, void *cookie)
{
    (void) cookie;
    parser.buffer[1] = data;
}

static void handle_dispatch2(uint8_t data, void *cookie)
{
    (void) cookie;
    parser.buffer[1] = data;
    if (parser.dispatch_cmd)
        parser.dispatch_cmd(parser.buffer);
}

static void handle_dispatch3(uint8_t data, void *cookie)
{
    (void) cookie;
    parser.buffer[2] = data;
    if (parser.dispatch_cmd)
        parser.dispatch_cmd(parser.buffer);
}

static void handle_sysex_start(uint8_t data, void *cookie)
{
    (void) data;
    (void) cookie;
    parser.offset = 0;
}

static void handle_sysex_data(uint8_t data, void *cookie)
{
    (void) cookie;
    if (parser.offset < sizeof(parser.buffer))
        parser.buffer[parser.offset++] = data;
}

static void handle_sysex_end(uint8_t data, void *cookie)
{
    (void) data;
    (void) cookie;

    // TODO: do something with the sysex message
}

// These events are common to all MIDI stream processing states
#define RESTART_EVENTS(STATE) \
    {STATE, 0xf0, 0x80, STATE_TRIPLE1, handle_start, dispatch_note_off}, \
    {STATE, 0xf0, 0x90, STATE_TRIPLE1, handle_start, dispatch_note_on}, \
    {STATE, 0xf0, 0xa0, STATE_TRIPLE1, handle_start, dispatch_aftertouch}, \
    {STATE, 0xf0, 0xb0, STATE_TRIPLE1, handle_start, dispatch_control_change}, \
    {STATE, 0xf0, 0xc0, STATE_DOUBLE1, handle_start, dispatch_program_change}, \
    {STATE, 0xf0, 0xd0, STATE_DOUBLE1, handle_start, dispatch_channel_pressure}, \
    {STATE, 0xf0, 0xe0, STATE_TRIPLE1, handle_start, dispatch_pitch_wheel}, \
    {STATE, 0xff, 0xf0, STATE_SYSEX, handle_sysex_start, NULL}, \
    {STATE, 0xff, 0xf1, STATE_DOUBLE1, handle_start, NULL}, /* MIDI Timing code (1 data byte) */  \
    {STATE, 0xff, 0xf2, STATE_TRIPLE1, handle_start, NULL}, /* Song position pointer (2 data bytes) */  \
    {STATE, 0xff, 0xf3, STATE_DOUBLE1, handle_start, NULL}, /* Song select (1 data byte) */  \
    {STATE, 0xff, 0xf6, STATE_IDLE, NULL, NULL}, /* Tune request (0 data bytes) */  \
    {STATE, 0xff, 0xf7, STATE_IDLE, NULL, NULL}, /* SysEx end (0 data bytes) */  \
    {STATE, 0xff, 0xf8, STATE_IDLE, NULL, NULL}, /* Timing clock (0 data bytes) */  \
    {STATE, 0xff, 0xfa, STATE_IDLE, NULL, NULL}, /* Start sequence (0 data bytes) */  \
    {STATE, 0xff, 0xfb, STATE_IDLE, NULL, NULL}, /* Continue sequence (0 data bytes) */  \
    {STATE, 0xff, 0xfc, STATE_IDLE, NULL, NULL}, /* Stop sequence (0 data bytes) */  \
    {STATE, 0xff, 0xfe, STATE_IDLE, NULL, NULL}, /* Active sensing (0 data bytes) */  \
    {STATE, 0xff, 0xff, STATE_IDLE, NULL, NULL}  /* System reset (0 data bytes) */

static struct midi_event state_machine[] =
{
    RESTART_EVENTS(STATE_IDLE),
    {STATE_IDLE, 0x00, 0x00, STATE_IDLE, NULL, NULL}, /* Ignore non-command */

    {STATE_TRIPLE1, 0x80, 0x00, STATE_TRIPLE2, handle_save_param1, NULL}, /* parameter 1 */
    RESTART_EVENTS(STATE_TRIPLE1),

    {STATE_TRIPLE2, 0x80, 0x00, STATE_IDLE, handle_dispatch3, NULL}, /* parameter 2 */
    RESTART_EVENTS(STATE_TRIPLE2),

    {STATE_DOUBLE1, 0x80, 0x00, STATE_IDLE, handle_dispatch2, NULL}, /* parameter 1 */
    RESTART_EVENTS(STATE_DOUBLE1),

    {STATE_SYSEX, 0x80, 0x00, STATE_SYSEX, handle_sysex_data, NULL},
    {STATE_SYSEX, 0xff, 0xf7, STATE_IDLE, handle_sysex_end, NULL},
    RESTART_EVENTS(STATE_DOUBLE1),

    {STATE_COUNT, 0, 0, STATE_IDLE, NULL, NULL} /* Sentinel */
};

static void init_parser()
{
    memset(&parser, 0, sizeof(parser));

    int ix = 0;
    for (int i = 0; i < STATE_COUNT; i++) {
        parser.event_start_ix[i] = ix;
        enum midi_parser_state state = state_machine[ix].state;
        while (state_machine[++ix].state == state);
    }
    // Save the last event
    parser.event_start_ix[STATE_COUNT] = ix;
}

static void process_midi_byte(uint8_t data)
{
    int begin_event = parser.event_start_ix[parser.state];
    int end_event = parser.event_start_ix[parser.state + 1];
    //fprintf(stderr, "Got data %02x. Scanning events %d-%d\r\n", data, begin_event, end_event);
    for (int i = begin_event; i < end_event; i++) {
        struct midi_event *event = &state_machine[i];
        //fprintf(stderr, "Checking %02x & %02x == %02x (%02x)\r\n", data, event->mask, event->value, (data & event->mask));
        if ((data & event->mask) == event->value) {
            // Matched event
            parser.state = event->next_state;
            if (event->handler)
                event->handler(data, event->cookie);

            break;
        }
    }
}

int main(int argc, char *argv[])
{
    fluid_settings_t *settings = new_fluid_settings ();
    synth = new_fluid_synth(settings);

    if (argc < 2)
        errx(EXIT_FAILURE, "midi_synth <soundfont path> [audio driver]");

    if (argc > 2) {
        // The second argument is the audio driver to use.
        fluid_settings_setstr(settings, "audio.driver", argv[2]);
    } else {
        // If the audio driver isn't specified, then use Fluidsynth's default or
        // the default that we want.
#ifdef OVERRIDE_AUDIO_DRIVER
        fluid_settings_setstr(settings, "audio.driver", OVERRIDE_AUDIO_DRIVER);
#endif
    }

    fluid_audio_driver_t *audiodriver = new_fluid_audio_driver (settings, synth);

    if (fluid_synth_sfload (synth, argv[1], 1) < 0)
        errx(EXIT_FAILURE, "fluid_synth_sfload(%s)", argv[1]);

    init_parser();

    for (;;) {
        uint8_t buffer[1024];
        ssize_t rc = read(STDIN_FILENO, buffer, sizeof(buffer));
        if (rc < 0) {
            if (errno == EINTR)
                continue;

            err(EXIT_FAILURE, "read");
        }
        if (rc == 0)
            break;

        for (int i = 0; i < rc; i++)
            process_midi_byte(buffer[i]);
    }

    delete_fluid_audio_driver(audiodriver);
    delete_fluid_synth(synth);
    delete_fluid_settings (settings);
    return 0;
}
