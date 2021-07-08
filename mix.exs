defmodule MIDISynth.MixProject do
  use Mix.Project

  @version "0.4.0"
  @source_url "https://github.com/fhunleth/midi_synth"

  def project do
    [
      app: :midi_synth,
      version: @version,
      elixir: "~> 1.6",
      package: package(),
      compilers: [:elixir_make | Mix.compilers()],
      aliases: [format: ["format", &format_c/1]],
      make_targets: ["all"],
      make_clean: ["clean"],
      docs: docs(),
      description: description(),
      start_permanent: Mix.env() == :prod,
      build_embedded: true,
      dialyzer: dialyzer(),
      deps: deps(),
      preferred_cli_env: %{
        docs: :docs,
        "hex.publish": :docs,
        "hex.build": :docs,
        credo: :test
      }
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp description do
    "MIDI synthesizer for Elixir"
  end

  defp package do
    [
      files: [
        "lib",
        "src/*.[ch]",
        "src/Makefile",
        "Makefile",
        "mix.exs",
        "README.md",
        "LICENSE",
        "CHANGELOG.md"
      ],
      licenses: ["Apache-2.0"],
      links: %{
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md",
        "GitHub" => @source_url
      }
    ]
  end

  defp deps do
    [
      {:elixir_make, "~> 0.6", runtime: false},
      {:ex_doc, "~> 0.22", only: :docs, runtime: false},
      {:dialyxir, "1.1.0", only: :dev, runtime: false},
      {:credo, "~> 1.2", only: :test, runtime: false}
    ]
  end

  defp dialyzer() do
    [
      flags: [:race_conditions, :unmatched_returns, :error_handling, :underspecs]
    ]
  end

  defp docs do
    [
      extras: ["README.md", "CHANGELOG.md", "LICENSE"],
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url,
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"]
    ]
  end

  defp format_c([]) do
    astyle =
      System.find_executable("astyle") ||
        Mix.raise("""
        Could not format C code since astyle is not available.
        """)

    System.cmd(astyle, ["-n", "src/*.c"], into: IO.stream(:stdio, :line))
  end

  defp format_c(_args), do: true
end
