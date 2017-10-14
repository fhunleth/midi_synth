#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <fluidsynth.h>
#include <err.h>
#include <stdint.h>
#include <unistd.h>
#include <errno.h>
#include <assert.h>

#define MIDI_STATUS_NOTE_OFF         0x80
#define MIDI_STATUS_NOTE_ON          0x90
#define MIDI_STATUS_AFTERTOUCH       0xa0
#define MIDI_STATUS_CONTROL_CHANGE   0xb0
#define MIDI_STATUS_PROGRAM_CHANGE   0xc0
#define MIDI_STATUS_CHANNEL_PRESSURE 0xd0
#define MIDI_STATUS_PITCH_WHEEL      0xe0
#define MIDI_STATUS_SYSEX            0xf0
#define MIDI_STATUS_END_SYSEX        0xf7

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
    fluid_synth_noteon(synth, buffer[0] & 0x0f, buffer[1], buffer[2]);
}
static void dispatch_note_off(const uint8_t *buffer)
{
    fluid_synth_noteoff(synth, buffer[0] & 0x0f, buffer[1]);
}
static void dispatch_aftertouch(const uint8_t *buffer)
{
    (void) buffer;
    // ???
}
static void dispatch_control_change(const uint8_t *buffer)
{
    switch (buffer[1]) {
    case 0x79: // Reset all controllers
        fluid_synth_system_reset(synth);
        break;
    case 0x7a: // Local control
        break;
    case 0x7b: // All notes off
        fluid_synth_all_notes_off(synth, buffer[0] & 0x0f);
        break;
    case 0x7c: // Omni mode off
        break;
    case 0x7d: // Omni mode on
        break;
    case 0x7e: // Mono mode on (Poly mode off)
        break;
    case 0x7f: // Poly mode on (Mono mode off)
        break;
    default:
        // ???
        break;
    }
}
static void dispatch_program_change(const uint8_t *buffer)
{
    fluid_synth_program_change(synth, buffer[0] & 0x0f, buffer[1]);
}
static void dispatch_channel_pressure(const uint8_t *buffer)
{
    fluid_synth_channel_pressure(synth, buffer[0] & 0x0f, buffer[1]);
}
static void dispatch_pitch_wheel(const uint8_t *buffer)
{
    fluid_synth_pitch_wheel_sens(synth, buffer[0] & 0x0f, (buffer[1] << 8) | buffer[2]);
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

// These events are common to all MIDI stream processing states
#define RESTART_EVENTS(STATE) \
    {STATE, 0xf0, 0x80, STATE_TRIPLE1, handle_start, dispatch_note_off}, \
    {STATE, 0xf0, 0x90, STATE_TRIPLE1, handle_start, dispatch_note_on}, \
    {STATE, 0xf0, 0xa0, STATE_TRIPLE1, handle_start, dispatch_aftertouch}, \
    {STATE, 0xf0, 0xb0, STATE_TRIPLE1, handle_start, dispatch_control_change}, \
    {STATE, 0xf0, 0xc0, STATE_DOUBLE1, handle_start, dispatch_program_change}, \
    {STATE, 0xf0, 0xd0, STATE_DOUBLE1, handle_start, dispatch_channel_pressure}, \
    {STATE, 0xf0, 0xe0, STATE_TRIPLE1, handle_start, dispatch_pitch_wheel}, \
    {STATE, 0xff, 0xf0, STATE_IDLE, NULL, NULL},   /* SysEx start */  \
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

    {STATE_COUNT, 0, 0, STATE_IDLE, NULL, NULL} /* Sentinal */
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

int main (int argc, char* argv[])
{
    fluid_settings_t *settings = new_fluid_settings ();

    /* create the synth, driver and sequencer instances */
    synth = new_fluid_synth(settings);
    fluid_settings_setstr(settings, "audio.driver", "pulseaudio");
    fluid_audio_driver_t *audiodriver = new_fluid_audio_driver (settings, synth);

    /* load a SoundFont */
    if (fluid_synth_sfload (synth, "FluidR3_GM.sf2", 1) < 0)
        errx(EXIT_FAILURE, "fluid_synth_sfload");

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
