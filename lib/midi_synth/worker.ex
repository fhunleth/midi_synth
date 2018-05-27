defmodule MidiSynth.Worker do
  require Logger
  use GenServer

  @moduledoc !"""
             Maintain the port process.
             """

  defmodule State do
    @moduledoc false
    defstruct port: nil
  end

  @spec start_link([term]) :: {:ok, pid}
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  @doc """
  Run a raw MIDI command.
  """
  def midi(pid, data) when is_binary(data) do
    GenServer.cast(pid, {:midi, data})
  end

  def play(pid, {note, duration}) when is_integer(note) and is_integer(duration) do
    GenServer.cast(pid, {:play, {note, duration}})
  end

  # gen_server callbacks
  def init(_args) do
    executable = :code.priv_dir(:midi_synth) ++ '/midi_synth'
    soundfont_path = Application.get_env(:midi_synth, :soundfont, default_soundfont())

    if soundfont_path == nil do
      raise "Please download and install FluidR3_GM.sf2.\nSee https://sourceforge.net/p/fluidsynth/wiki/GettingStarted/\n. Then add the install path to your config. See README.md."
    end

    port =
      Port.open({:spawn_executable, executable}, [
        {:args, [soundfont_path]},
        :stream,
        :use_stdio,
        :binary,
        :exit_status
      ])

    state = %State{port: port}
    {:ok, state}
  end

  def handle_cast({:midi, data}, state) do
    send_midi(state, data)
    {:noreply, state}
  end

  def handle_cast({:play, {note, duration}}, state) do
    send_midi(state, note_on(note, 127))
    Process.send_after(self(), {:midi, note_off(note)}, duration)

    {:noreply, state}
  end

  def handle_info({:midi, data}, state) do
    send_midi(state, data)
    {:noreply, state}
  end

  defp send_midi(state, data) do
    send(state.port, {self(), {:command, data}})
  end

  defp note_on(note, velocity), do: <<0x90, note, velocity>>
  defp note_off(note), do: <<0x80, note, 64>>

  defp default_soundfont() do
    locations = [
      "/usr/share/sounds/sf2/FluidR3_GM.sf2",
      Application.app_dir(:midi_synth, "priv/FluidR3_GM.sf2")
    ]

    locations
    |> Enum.find(&File.exists?/1)
  end
end
