defmodule MIDISynthTest do
  use ExUnit.Case

  import ExUnit.CaptureLog
  doctest MIDISynth

  test "playing raw midi strings" do
    synth = start_supervised!(MIDISynth)
    MIDISynth.midi(synth, <<0x90, 60, 127>>)
    Process.sleep(250)
    MIDISynth.midi(synth, <<0x80, 60, 127>>)
  end

  @tag :requires_working_audio
  test "MIDISynth exits when port crashes" do
    Process.flag(:trap_exit, true)

    capture_log(fn ->
      {:ok, synth} = MIDISynth.start_link([])
      System.cmd("killall", ["midi_synth"])

      assert_receive {:EXIT, ^synth, message}
      assert message =~ "unexpected exit"
    end)
  end
end
