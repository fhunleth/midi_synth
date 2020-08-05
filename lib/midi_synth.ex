defmodule MIDISynth do
  use GenServer

  @moduledoc """
  Play music in Elixir!
  """

  @doc """
  Start a MIDI synthesizer

  Synthesizer arguments:

  * `:soundfont` - the path to the sound font to use for synthesize. Uses FluidR2_GM.sf2 by default.
  """
  @spec start_link(keyword(), GenServer.options()) :: GenServer.on_start()
  def start_link(args, opts \\ []) do
    args = validate_soundfont(args)
    GenServer.start_link(__MODULE__, args, opts)
  end

  @doc """
  Send a raw MIDI command to the synthesizer

  See `MIDISynth.Command` for encoding MIDI commands and `MIDISynth.Keyboard`
  for playing simple songs.

  ## Examples

    iex> {:ok, synth} = MIDISynth.start_link([])
    iex> MIDISynth.midi(synth, <<0x90, 60, 127>>)
    :ok

  """
  @spec midi(GenServer.server(), binary()) :: :ok
  def midi(server, data) when is_binary(data) do
    GenServer.cast(server, {:midi, data})
  end

  @impl GenServer
  def init(args) do
    soundfont_path = Keyword.fetch!(args, :soundfont)
    executable = Application.app_dir(:midi_synth, ["priv", "midi_synth"])

    port =
      Port.open({:spawn_executable, executable}, [
        {:args, [soundfont_path]},
        :stream,
        :use_stdio,
        :binary,
        :exit_status
      ])

    {:ok, port}
  end

  @impl GenServer
  def handle_cast({:midi, data}, port) do
    send(port, {self(), {:command, data}})
    {:noreply, port}
  end

  @impl GenServer
  def handle_info({port, {:exit_status, status}}, port) do
    {:stop, "midi_synth unexpected exited with status #{status}", nil}
  end

  defp validate_soundfont(args) do
    soundfont_path =
      Keyword.get(args, :soundfont, Application.app_dir(:midi_synth, ["priv", "FluidR3_GM.sf2"]))

    if File.exists?(soundfont_path) do
      Keyword.put(args, :soundfont, soundfont_path)
    else
      raise ArgumentError,
            "Could not find '#{soundfont_path}'.\nCheck the `:soundfont` option to MIDISynth.start_link/2."
    end
  end
end
