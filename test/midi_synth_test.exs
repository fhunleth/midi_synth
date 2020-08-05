defmodule MidiSynthTest do
  use ExUnit.Case

  import ExUnit.CaptureLog
  doctest MidiSynth

  test "playing raw midi strings" do
    synth = start_supervised!(MidiSynth)
    MidiSynth.midi(synth, <<0x90, 60, 127>>)
    Process.sleep(250)
    MidiSynth.midi(synth, <<0x80, 60, 127>>)
  end

  @tag :requires_working_audio
  test "MidiSynth exits when port crashes" do
    Process.flag(:trap_exit, true)

    capture_log(fn ->
      {:ok, synth} = MidiSynth.start_link([])
      System.cmd("killall", ["midi_synth"])

      assert_receive {:EXIT, ^synth, message}
      assert message =~ "unexpected exit"
    end)
  end
end
