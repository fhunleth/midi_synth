# MidiSynth

**TODO: Add description**

## Installation

Eventually this project will be multiplatform, but right now it
only runs on Linux w/ PulseAudio. If you're running Ubuntu or
probably most other mainstream distributions, you should be ok.

It uses [FluidSynth](http://www.fluidsynth.org/) to play notes.
Install it before compiling the C code in this project:

```sh
$ sudo apt install libfluidsynth-dev
```

Clone the project and try it out:

```sh
$ git clone https://fhunleth@bitbucket.org/fhunleth/midi_synth.git
$ cd midi_synth
$ iex -S mix

# Play a middle C for 100 ms
iex> MidiSynth.play({60, 100}
```

