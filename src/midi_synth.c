#include <stdlib.h>
#include <stdio.h>
#include <fluidsynth.h>
#include <err.h>
#include <stdint.h>
#include <unistd.h>
#include <errno.h>

#define MIDI_STATUS_NOTE_OFF         0x80
#define MIDI_STATUS_NOTE_ON          0x90
#define MIDI_STATUS_AFTERTOUCH       0xa0
#define MIDI_STATUS_CONTROL_CHANGE   0xb0
#define MIDI_STATUS_PROGRAM_CHANGE   0xc0
#define MIDI_STATUS_CHANNEL_PRESSURE 0xd0
#define MIDI_STATUS_PITCH_WHEEL      0xe0
#define MIDI_STATUS_SYSEX            0xf0
#define MIDI_STATUS_END_SYSEX        0xf7

static void handle_midi(fluid_synth_t *synth, const uint8_t *buffer, size_t len)
{
    switch(buffer[0] & 0xf0) {
    case MIDI_STATUS_NOTE_ON:
        fluid_synth_noteon(synth, buffer[0] & 0x0f, buffer[1], buffer[2]);
        break;
    case MIDI_STATUS_NOTE_OFF:
        fluid_synth_noteoff(synth, buffer[0] & 0x0f, buffer[1]);
        break;
    default:
        break;
    }
}

int main (int argc, char* argv[])
{
    fluid_settings_t *settings = new_fluid_settings ();

    /* create the synth, driver and sequencer instances */
    fluid_synth_t *synth = new_fluid_synth (settings);
    fluid_settings_setstr(settings, "audio.driver", "pulseaudio");
    fluid_audio_driver_t *audiodriver = new_fluid_audio_driver (settings, synth);

    /* load a SoundFont */
    if (fluid_synth_sfload (synth, "FluidR3_GM.sf2", 1) < 0)
        errx(EXIT_FAILURE, "fluid_synth_sfload");

    for (;;) {
        uint8_t buffer[3];
        ssize_t rc = read(STDIN_FILENO, buffer, sizeof(buffer));
        if (rc < 0) {
            if (errno == EINTR)
                continue;

            err(EXIT_FAILURE, "read");
        }
        if (rc == 0)
            break;

        handle_midi(synth, buffer, rc);

    }
//fluid_synth_program_change(synth, 0, 100);
    delete_fluid_audio_driver(audiodriver);
    delete_fluid_synth(synth);
    delete_fluid_settings (settings);
    return 0;
}
