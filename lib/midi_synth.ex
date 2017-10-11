defmodule MidiSynth do
  use GenServer

  @moduledoc """
  Documentation for MidiSynth.
  """

  defmodule State do
    @moduledoc false
    defstruct port: nil
  end

  @doc """
  Hello world.

  ## Examples

      iex> MidiSynth.hello
      :world

  """
  def hello do
    :world
  end

  @spec start_link([term]) :: {:ok, pid}
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def midi(pid, data) when is_binary(data) do
    GenServer.cast(pid, {:midi, data})
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
    send(state.port, {self(), {:command, data}})
    {:noreply, state}
  end
end
