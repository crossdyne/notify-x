defmodule Notifier.MixProject do
  use Mix.Project

  def project do
    [
      app: :notifier,
      version: "1.0.0",
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  def application do
    [
      mod: {Notifier.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:broadway_kafka, "~> 0.4.0"},
      {:swoosh, "~> 1.14"},
      {:gen_smtp, "~> 1.2"},
      {:jason, "~> 1.4"},
      {:dotenvy, "~> 0.7"}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get"]
    ]
  end
end
