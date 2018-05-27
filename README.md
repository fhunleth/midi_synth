# MidiSynth

Play music in Elixir.

## Installation

This project requires [FluidSynth](http://www.fluidsynth.org/) and a SoundFont
file to work.

First install FluidSynth:

On Linux:
```sh
sudo apt install libfluidsynth-dev
```

On OSX:
```sh
brew install fluidsynth
```

The next step is to download a SoundFont file. I recommend starting with
`FluidR3_GM.sf2` since it supports the [General
MIDI](https://en.wikipedia.org/wiki/General_MIDI) instruments. It is Creative
Commons-licensed but too large to be bundled with `midi_synth` (Some help here
to make this easier would be great!).  The best way to find it appears to be to
Google for a link or if you're on Linux to install `fluid-soundfont-gm`.

Next, clone the project and build it the normal Elixir ways:

```sh
git clone https://github.com/fhunleth/midi_synth.git
cd midi_synth
mix deps.get
# Copy the sf2 file to the priv directory
cp <path_to>FluidR3_GM.sf2 priv
mix test
```

Copying the soundfont file to `priv` isn't necessary. You can also specify its
path in your `config.exs` (see `config/config.exs` in this project) or let
`midi_synth` guess its location.

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

The current value of this library is the port process that interfaces with the
FluidSynth library. The Elixir code barely scratches the surface with what's
possible. If you're comfortable with raw MIDI commands, try this out:

```elixir
iex> MidiSynth.midi(<<0x90, 60, 127>>)
iex> MidiSynth.midi(<<0x80, 60, 127>>)
```

## License

The Elixir and C code is covered by the Apache 2 License.
