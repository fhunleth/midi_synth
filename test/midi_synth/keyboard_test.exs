defmodule MidiSynth.KeyboardTest do
  use ExUnit.Case

  alias MidiSynth.Keyboard
  doctest Keyboard

  test "playing notes" do
    synth = start_supervised!(MidiSynth)
    Keyboard.change_program(synth, 57)
    Keyboard.play(synth, 60, 250)
    Keyboard.play(synth, 67, 250)
    Keyboard.play(synth, 72, 250)
    Keyboard.play(synth, 76, 400)
    Keyboard.play(synth, 72, 250)
    Keyboard.play(synth, 76, 500)
  end
end
