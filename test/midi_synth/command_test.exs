defmodule MidiSynth.CommandTest do
  use ExUnit.Case

  alias MidiSynth.Command
  doctest Command

  test "note on" do
    assert <<0x90, 60, 80>> == Command.note_on(60, 80)
  end

  test "note off" do
    assert <<0x80, 60, 64>> == Command.note_off(60)
  end

  test "change program" do
    assert <<0xC0, 9>> == Command.change_program(10)
  end
end
