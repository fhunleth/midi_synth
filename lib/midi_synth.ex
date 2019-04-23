defmodule MidiSynth do
  alias MidiSynth.Worker

  @moduledoc """
  Play music in Elixir!
  """

  @doc """
  Send a raw MIDI command to the synthesizer.

  ## Examples

      iex> MidiSynth.midi(<<0x90, 60, 127>>)
      :ok

  """
  def midi(data) when is_binary(data) do
    Worker.midi(MidiSynth.Worker, data)
  end

  @doc """
  Play a note.

  ## Examples

      iex> MidiSynth.play(60, 100)
      :ok

      iex> MidiSynth.play(60, 100, 80)
      :ok
  """
  def play(note, duration, velocity \\ 127) do
    Worker.play(MidiSynth.Worker, {note, duration, velocity})
  end

  @doc """
  Change the current program (e.g., the current instrument).
  """
  def change_program(prog) when prog > 0 and prog <= 128 do
    midi(<<0xC0, prog - 1>>)
  end
end
