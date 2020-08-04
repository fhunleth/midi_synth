defmodule MidiSynth do
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

  See `MidiSynth.Command` for encoding MIDI commands and `MidiSynth.Keyboard`
  for playing simple songs.

  ## Examples

    iex> {:ok, synth} = MidiSynth.start_link([])
    iex> MidiSynth.midi(synth, <<0x90, 60, 127>>)
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

  defp validate_soundfont(args) do
    soundfont_path =
      Keyword.get(args, :soundfont, Application.app_dir(:midi_synth, ["priv", "FluidR3_GM.sf2"]))

    if File.exists?(soundfont_path) do
      Keyword.put(args, :soundfont, soundfont_path)
    else
      raise ArgumentError,
            "Please download and install FluidR3_GM.sf2.\nSee https://sourceforge.net/p/fluidsynth/wiki/GettingStarted/\n. Then add the install path to your config. See README.md."
    end
  end
end
