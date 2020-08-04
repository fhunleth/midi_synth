defmodule MidiSynthTest do
  use ExUnit.Case
  doctest MidiSynth

  test "playing raw midi strings" do
    synth = start_supervised!(MidiSynth)
    MidiSynth.midi(synth, <<0x90, 60, 127>>)
    Process.sleep(250)
    MidiSynth.midi(synth, <<0x80, 60, 127>>)
  end

  # test "playing notes" do
  #   synth = start_supervised!(MidiSynth)
  #   MidiSynth.change_program(synth, 57)
  #   MidiSynth.play(synth, 60, 250)
  #   MidiSynth.play(synth, 67, 250)
  #   MidiSynth.play(synth, 72, 250)
  #   MidiSynth.play(synth, 76, 400)
  #   MidiSynth.play(synth, 72, 250)
  #   MidiSynth.play(synth, 76, 500)
  # end
end
