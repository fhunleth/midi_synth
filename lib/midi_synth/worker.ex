defmodule MidiSynth.Worker do
  require Logger
  use GenServer

  @moduledoc """
  Documentation for MidiSynth.Worker.
  """

  defmodule State do
    @moduledoc false
    defstruct port: nil, tempo: 120
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
  def init([]) do
    priv_dir = :code.priv_dir(:midi_synth)
    executable = priv_dir ++ '/midi_synth'

    port =
      Port.open({:spawn_executable, executable}, [
        {:args, []},
        :stream,
        {:cd, priv_dir},
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
end
