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

  @typedoc "A MIDI channel number"
  @type channel :: 0..15

  @doc """
  Turn a note in a channel on.
  """
  @spec note_on(channel(), note(), velocity()) :: binary()
  def note_on(channel, note, velocity) do
    <<0x9::4, channel::4, note, velocity>>
  end

  @doc """
  Turn a note in a channel off.
  """
  @spec note_off(channel(), note()) :: binary()
  def note_off(channel, note) do
    <<0x8::4, channel::4, note, 64>>
  end

  @doc """
  Turn all active notes in a channel off.
  """
  @spec note_off_all(channel()) :: binary()
  def note_off_all(channel) do
    <<0xB::4, channel::4, 123, 0>>
  end

  @doc """
  Change the current program (e.g. instrument) of a channel.
  """
  @spec change_program(channel(), program()) :: <<_::16>>
  def change_program(channel, prog) when prog > 0 and prog <= 128 do
    <<0xC::4, channel::4, prog - 1>>
  end
end
