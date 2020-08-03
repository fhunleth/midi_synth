defmodule MidiSynth do
  alias MidiSynth.Worker

  @moduledoc """
  Play music in Elixir!
  """

  @typedoc """
  A MIDI note

  For non-percussion instruments, the frequency of a note
  is `440 * 2^((n − 69) / 12)` where `n` is the note number.

  Middle C is 60
  """
  @type note :: 0..127

  @typedoc """
  The duration in milliseconds for which to hold down a note.
  """
  @type duration :: non_neg_integer()

  @typedoc """
  The velocity to strike the note.

  127 = maximum velocity
  """
  @type velocity :: 0..127

  @typedoc "A MIDI program"
  @type program :: 1..128

  @doc """
  Send a raw MIDI command to the synthesizer.

  ## Examples

      iex> MidiSynth.midi(<<0x90, 60, 127>>)
      :ok

  """
  @spec midi(binary()) :: :ok
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
  @spec play(note(), duration(), velocity()) :: :ok
  def play(note, duration, velocity \\ 127) do
    Worker.play(MidiSynth.Worker, {note, duration, velocity})
  end

  @doc """
  Change the current program (e.g., the current instrument).
  """
  @spec change_program(program()) :: :ok
  def change_program(prog) when prog > 0 and prog <= 128 do
    midi(<<0xC0, prog - 1>>)
  end
end
