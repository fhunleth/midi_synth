defmodule MidiSynthTest do
  use ExUnit.Case
  doctest MidiSynth

  test "playing raw midi strings" do
    MidiSynth.midi(<<0x90, 60, 127>>)
    Process.sleep(250)
    MidiSynth.midi(<<0x80, 60, 127>>)
  end

  test "playing notes" do
    MidiSynth.change_program(57)
    MidiSynth.play(60, 250)
    Process.sleep(250)
    MidiSynth.play(67, 250)
    Process.sleep(250)
    MidiSynth.play(72, 250)
    Process.sleep(250)
    MidiSynth.play(76, 400)
    Process.sleep(500)
    MidiSynth.play(72, 250)
    Process.sleep(250)
    MidiSynth.play(76, 1000)
    Process.sleep(1000)
  end
end
