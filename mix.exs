defmodule MidiSynth.Mixfile do
  use Mix.Project

  @version "0.1.0"

  @description """
  MIDI synthesizer for Elixir.
  """

  def project do
    [
      app: :midi_synth,
      version: @version,
      elixir: "~> 1.5",
      description: @description,
      package: package(),
      compilers: [:elixir_make] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {MidiSynth.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:elixir_make, "~> 0.4", runtime: false},
      {:ex_doc, "~> 0.11", only: :dev}
    ]
  end

  defp package() do
    [
      maintainers: ["Frank Hunleth"],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/fhunleth/midi_synth"}
    ]
  end
end
