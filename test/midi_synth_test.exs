defmodule MidiSynthTest do
  use ExUnit.Case
  doctest MidiSynth

  test "plays a raw midi" do
    MidiSynth.midi(<<0x90, 60, 127>>)
    :timer.sleep(1000)
    MidiSynth.midi(<<0x80, 60, 127>>)

  end
end
