defmodule MidiSynth.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Starts a worker by calling: MidiSynth.Worker.start_link(arg)
      {MidiSynth.Worker, [name: MidiSynth.Worker]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MidiSynth.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
