# MIDISynth

[![Hex version](https://img.shields.io/hexpm/v/midi_synth.svg "Hex version")](https://hex.pm/packages/midi_synth)
[![CircleCI](https://circleci.com/gh/fhunleth/midi_synth.svg?style=svg)](https://circleci.com/gh/fhunleth/midi_synth)

Play music in Elixir.

## Trying it out

First, install [FluidSynth](http://www.fluidsynth.org/).

On Linux:

```sh
sudo apt install libfluidsynth-dev
```

On OSX:

```sh
brew install fluidsynth
```

Next, either clone this library or pull it in as a dependency to your Elixir
project. The following is an example of the dependency for your `mix.exs`:

```elixir
  {:midi_synth, "~> 0.3"}
```

Fetch dependencies and build as you normally would. The first build will
download the `FluidR3_GM.sf2` soundfont file. This is a Creative
Commons-licensed data file that contains all of the [General
MIDI](https://en.wikipedia.org/wiki/General_MIDI) instruments. It is a good
place to start, but can be changed later on.

## Try it out using IEx

Start IEx by running `iex -S mix` from a shell prompt.

`MIDISynth` is a `GenServer` and must be started first. The library comes with
with helpers to make playing simple things easy. For more complicated uses,
you'll want to build on this library.

OK, let's play a note. Notes are numbered sequentially. Middle C is note 60.
Here's how to play middle C for 100 ms.

```elixir
iex> {:ok, synth} = MIDISynth.start_link([])
{:ok, #PID<0.226.0>}
iex> MIDISynth.Keyboard.play(synth, 60, 100)
```

You can play the same note with a different velocity. The velocities range from
1 to 127. Here's how to play middle C for 100 ms with velocity mezzo-forte: 80.

```elixir
iex> MIDISynth.Keyboard.play(synth, 60, 100, 80)
```

If you don't like the piano, try switching the instrument to something else. For
example, trumpets ([General MIDI
instrument](https://www.midi.org/specifications-old/item/gm-level-1-sound-set)
57) are nice:

```elixir
iex> MIDISynth.Keyboard.change_program(synth, 57)
iex> MIDISynth.Keyboard.play(synth, 60, 500)
```

Percussion instruments can be played only through MIDI channel 9.
For example, this is how to play a cowbell sound:

```elixir
iex> MIDISynth.Keyboard.play(synth, 56, 0, 127, 9)
```

The real value of this library is the ability to send raw MIDI messages to the
FluidSynth library. The Elixir code barely scratches the surface of what's
possible. If you're comfortable with raw [MIDI
commands](https://www.midi.org/specifications/item/table-1-summary-of-midi-message),
try this out:

```elixir
iex> MIDISynth.midi(synth, <<0x90, 60, 127>>)
iex> MIDISynth.midi(synth, <<0x80, 60, 127>>)
```

See `MIDISynth.Command` for help with encoding messages, and please feel free to
add more.

## License

The Elixir and C code are covered by the Apache 2 License.
