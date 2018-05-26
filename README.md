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
iex> MidiSynth.play({60, 100})
```

