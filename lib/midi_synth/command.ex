defmodule MIDISynth.Command do
  @moduledoc """
  Convert MIDI commands to raw bytes
  """

  defguardp is_int7(num) when num >= 0 and num <= 127

  @typedoc "A 7-bit integer"
  @type int7 :: 0..127

  @typedoc """
  A MIDI note

  For non-percussion instruments, the frequency of a note
  is `440 * 2^((n − 69) / 12)` where `n` is the note number.

  Middle C is 60
  """
  @type note :: int7()

  @typedoc """
  The duration in milliseconds for which to hold down a note.
  """
  @type duration :: non_neg_integer()

  @typedoc """
  The velocity to strike the note.

  127 = maximum velocity
  """
  @type velocity :: int7()

  @typedoc "A MIDI program"
  @type program :: int7()

  @typedoc "A MIDI channel number"
  @type channel :: 0..15

  @typedoc "A channel volume"
  @type volume :: int7()

  @doc """
  Turn a note in a channel on.
  """
  @spec note_on(channel(), note(), velocity()) :: <<_::24>>
  def note_on(channel, note, velocity) do
    <<0x9::4, channel::4, note, velocity>>
  end

  @doc """
  Turn a note in a channel off.
  """
  @spec note_off(channel(), note()) :: <<_::24>>
  def note_off(channel, note) do
    <<0x8::4, channel::4, note, 64>>
  end

  @doc """
  Change the current program (e.g. instrument) of a channel.
  """
  @spec change_program(channel(), program()) :: <<_::16>>
  def change_program(channel, prog) when is_int7(prog) do
    <<0xC::4, channel::4, prog>>
  end

  @doc """
  Turn all active notes in a channel off.
  """
  @spec note_off_all(channel()) :: <<_::24>>
  def note_off_all(channel) do
    change_control(channel, 123)
  end

  @doc """
  Change the volume of a MIDI channel.
  This change is applied to all playing and future notes.
  """
  @spec change_volume(channel(), int7()) :: <<_::24>>
  def change_volume(channel, volume) when is_int7(volume) do
    change_control(channel, 7, volume)
  end

  @doc """
  Bend the pitch of notes playing in a channel.
  Values below 0x2000 will decrease the pitch, and higher values will increase it.
  """
  @spec pitch_bend(channel(), integer()) :: <<_::24>>
  def pitch_bend(channel, bend) when bend >= 0 and bend < 0x4000 do
    <<msb::7, lsb::7>> = <<bend::14>>
    <<0xE::4, channel::4, lsb, msb>>
  end

  @doc """
  Change the sound bank of a channel.
  """
  @spec change_sound_bank(channel(), integer()) :: <<_::48>>
  def change_sound_bank(channel, bank) when bank >= 0 and bank < 0x4000 do
    <<msb::7, lsb::7>> = <<bank::14>>
    msb_binary = change_control(channel, 0, msb)
    lsb_binary = change_control(channel, 0x20, lsb)
    <<msb_binary::binary, lsb_binary::binary>>
  end

  @doc """
  Change the panoramic (pan) of a channel.
  This shifts the sound from the left or right ear in when playing stereo.
  Values below 64 moves the sound to the left, and above to the right.
  """
  @spec pan(channel(), int7()) :: <<_::24>>
  def pan(channel, pan) when is_int7(pan) do
    change_control(channel, 10, pan)
  end

  @doc """
  Change the MIDI controller value of a channel.
  """
  @spec change_control(channel(), int7(), int7()) :: <<_::24>>
  def change_control(channel, control_number, control_value \\ 0)
      when is_int7(control_number) and is_int7(control_value) do
    <<0xB::4, channel::4, control_number, control_value>>
  end
end
