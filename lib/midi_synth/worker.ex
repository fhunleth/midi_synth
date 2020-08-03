defmodule MidiSynth.Worker do
  use GenServer
  require Logger

  @moduledoc false

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
  @spec midi(GenServer.server(), binary()) :: :ok
  def midi(pid, data) when is_binary(data) do
    GenServer.cast(pid, {:midi, data})
  end

  @spec play(GenServer.server(), {non_neg_integer(), non_neg_integer(), non_neg_integer()}) :: :ok
  def play(pid, {note, duration, velocity})
      when is_integer(note) and
             is_integer(duration) and
             is_integer(velocity) do
    GenServer.cast(pid, {:play, {note, duration, velocity}})
  end

  @impl GenServer
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

  @impl GenServer
  def handle_cast({:midi, data}, state) do
    send_midi(state, data)
    {:noreply, state}
  end

  def handle_cast({:play, {note, duration, velocity}}, state) do
    send_midi(state, note_on(note, velocity))
    Process.send_after(self(), {:midi, note_off(note)}, duration)
    {:noreply, state}
  end

  @impl GenServer
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
      Application.app_dir(:midi_synth, "priv/FluidR3_GM.sf2"),
      "/usr/share/sounds/sf2/FluidR3_GM.sf2"
    ]

    locations
    |> Enum.find(&File.exists?/1)
  end
end
