defmodule MidiSynth.Keyboard do
  alias MidiSynth.Command

  @moduledoc """
  Simple keyboard functions for sending MIDI commands to the synthesizer
  """

  @doc """
  Play a note

  This is a utility method for pressing a note down and then releasing it after
  a duration.

  ## Example

    iex> {:ok, synth} = MidiSynth.start_link([])
    iex> MidiSynth.Keyboard.play(synth, 60, 100)
    :ok
    iex> MidiSynth.Keyboard.play(synth, 60, 100, 80)
    :ok
  """
  @spec play(GenServer.server(), Command.note(), Command.duration(), Command.velocity()) :: :ok
  def play(server, note, duration, velocity \\ 127) do
    MidiSynth.midi(server, Command.note_on(note, velocity))
    Process.sleep(duration)
    MidiSynth.midi(server, Command.note_off(note))
  end

  @doc """
  Change the current program (e.g., the current instrument)

  The soundfont that's supplied to `MidiSynth.start_link/2` determines the
  mapping from program numbers to instruments. The default is to use a general
  MIDI soundfont, and instrument mappings for those can be found by looking at
  the [General MIDI
  1](https://www.midi.org/specifications-old/item/gm-level-1-sound-set) and
  [General MIDI 2](https://www.midi.org/specifications-old/item/general-midi-2)
  specifications.

  ## Example

    # Play a violin
    iex> {:ok, synth} = MidiSynth.start_link([])
    iex> MidiSynth.Keyboard.change_program(synth, 41)
    :ok
    iex> MidiSynth.Keyboard.play(synth, 60, 100)
    :ok
  """
  @spec change_program(GenServer.server(), Command.program()) :: :ok
  def change_program(server, prog) do
    MidiSynth.midi(server, Command.change_program(prog))
  end
end
