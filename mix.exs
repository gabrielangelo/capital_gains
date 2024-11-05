defmodule CapitalGains.MixProject do
  @moduledoc false

  use Mix.Project

  def project do
    [
      app: :capital_gains,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.cobertura": :test
      ],
      # Add escript configuration
      escript: escript(),
      # Makes `mix` build the executable by default
      default_task: "escript.build"
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:excoveralls, "~> 0.18", only: :test},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:decimal, "~> 2.0"},
      {:poison, "~> 6.0"}
    ]
  end

  defp escript do
    [
      main_module: CapitalGains.Infrastructure.CLI,
      name: :capital_gains,
      comment: "Capital Gains Tax Calculator"
    ]
  end
end
