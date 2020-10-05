defmodule MIDISynth.Command do
  @moduledoc """
  Convert MIDI commands to raw bytes
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

  @typedoc "The MIDI channel number"
  @type channel :: 0..15

  @doc """
  Press a key down
  """
  @spec note_on(note(), velocity(), channel()) :: binary()
  def note_on(note, velocity, channel) do
    <<0x90 + channel, note, velocity>>
  end

  @doc """
  Release a key
  """
  @spec note_off(note(), channel()) :: binary()
  def note_off(note, channel) do
    <<0x80 + channel, note, 64>>
  end

  @doc """
  Change the current program (e.g., the current instrument).
  """
  @spec change_program(program(), channel()) :: <<_::16>>
  def change_program(prog, channel) when prog > 0 and prog <= 128 do
    <<0xC0 + channel, prog - 1>>
  end
end
