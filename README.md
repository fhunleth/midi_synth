# MidiSynth

Play music in Elixir.

## Installation

This project requires [FluidSynth](http://www.fluidsynth.org/) to play notes.
First install it.

On Linux:
```sh
sudo apt install libfluidsynth-dev
```

On OSX:
```sh
brew install fluidsynth
```

Next, clone the project and build it the normal Elixir ways:

```sh
git clone https://fhunleth@bitbucket.org/fhunleth/midi_synth.git
cd midi_synth
mix deps.get
mix compile
```

## Try it out using IEx

Start IEx by running `iex -S mix` from a shell prompt.

Now try playing a node. Notes are numbered sequentially with middle C being 60.
Here's how to play middle C for 100 ms.

```elixir
iex> MidiSynth.play(60, 100)
```

If you don't like the piano, switch the instrument to something else. For
example, trumpets (General MIDI instrument 57) are nice:

```elixir
iex> MidiSynth.change_program(57)
iex> MidiSynth.play(60, 500)
```

MidiSynth currently comes with the General MIDI set of instruments. A full list
is at [wikipedia/General_MIDI](https://en.wikipedia.org/wiki/General_MIDI).

The current value of this library is the port process that interfaces with the
FluidSynth library. The Elixir code barely scratches the surface with what's
possible. If you're comfortable with raw MIDI commands, try this out:

```elixir
iex> MidiSynth.midi(<<0x90, 60, 127>>)
iex> MidiSynth.midi(<<0x80, 60, 127>>)
```

## License

The Elixir and C code is covered by the Apache 2 License. The `FluidR3_GM.sf2`
file has the Creative Commons License.
