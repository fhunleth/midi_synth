# MidiSynth

Play music in Elixir.

## Trying it out

First, clone the project:

```sh
git clone https://github.com/fhunleth/midi_synth.git
```

Next, install [FluidSynth](http://www.fluidsynth.org/).

On Linux:

```sh
sudo apt install libfluidsynth-dev
```

On OSX:

```sh
brew install fluidsynth
```

Next, build the project the normal Elixir way. The first build will download the
`FluidR3_GM.sf2` soundfont file. This is a Creative Commons-licensed data file
that contains all of the [General
MIDI](https://en.wikipedia.org/wiki/General_MIDI) instruments. It is a good
place to start, but can be changed later on.

```sh
cd midi_synth
mix deps.get
mix test
```

If it works, `mix test` should play a short song.

## Try it out using IEx

Start IEx by running `iex -S mix` from a shell prompt.

Now try playing a note. Notes are numbered sequentially. Middle C is note 60.
Here's how to play middle C for 100 ms.

```elixir
iex> MidiSynth.play(60, 100)
```

You can play the same note with a different velocity. The velocities range from 1 to 127. Here's how to play middle C for 100 ms with velocity mezzo-forte: 80.

```elixir
iex> MidiSynth.play(60, 100, 80)
```

If you don't like the piano, try switching the instrument to something else. For
example, trumpets (General MIDI instrument 57) are nice:

```elixir
iex> MidiSynth.change_program(57)
iex> MidiSynth.play(60, 500)
```

The real value of this library is the port process that interfaces with the
FluidSynth library. The Elixir code barely scratches the surface of what's
possible. If you're comfortable with raw [MIDI
commands](https://www.midi.org/specifications/item/table-1-summary-of-midi-message),
try this out:

```elixir
iex> MidiSynth.midi(<<0x90, 60, 127>>)
iex> MidiSynth.midi(<<0x80, 60, 127>>)
```

## License

The Elixir and C code is covered by the Apache 2 License.
