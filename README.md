# MidiSynth

Play music in Elixir.

## Trying it out

First, clone the project:

```sh
git clone https://github.com/fhunleth/midi_synth.git
```

Next, install [FluidSynth](http://www.fluidsynth.org/) and a SoundFont file that
supports [General MIDI](https://en.wikipedia.org/wiki/General_MIDI) instruments.
I recommend starting with `FluidR3_GM.sf2` which has a complete set of
instruments and is Creative Commons-licensed.

On Linux:

```sh
sudo apt install libfluidsynth-dev fluid-soundfont-gm
# The SoundFont file will be in /usr/share/sounds/sf2/FluidR3_GM.sf2. MidiSynth
# will find it.
```

On OSX:

```sh
brew install fluidsynth

# Install FluidR3_GM.sf2 to the priv directory in midi_synth. (I'd like to
# improve this, but this will work for trying midi_synth out)
cd midi_synth
mkdir priv
cd priv
curl -LO https://github.com/fhunleth/midi_synth/releases/download/v0.1.0/FluidR3_GM.sf2
```

Next, build the project the normal Elixir way:

```sh
cd midi_synth
mix deps.get
mix test
```

FYI: Copying the soundfont file to `priv` or using Debian's install location isn't the
only option. You can also specify its path in your `config.exs` (see
`config/config.exs` in this project) or let `midi_synth` guess its location.

## Try it out using IEx

Start IEx by running `iex -S mix` from a shell prompt.

Now try playing a node. Notes are numbered sequentially. Middle C is note 60.
Here's how to play middle C for 100 ms.

```elixir
iex> MidiSynth.play(60, 100)
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
