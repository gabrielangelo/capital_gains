defmodule CapitalGains.Infrastructure.Cli.CliArgParser do
  @moduledoc false

  @spec parse_args(list(String.t())) :: Optimus.ParseResult.t()
  def parse_args(args) do
    optimus =
      Optimus.new!(
        name: "capital_gains",
        description: "Calculate capital gains tax for stock operations",
        version: "1.0.0",
        author: "John Constantine",
        about: "A tool for calculating capital gains tax according to Brazilian rules",
        allow_unknown_args: false,
        parse_double_dash: true,
        options: [
          file: [
            value_name: "FILE",
            short: "-f",
            long: "--file",
            help: "Input file containing operations (JSON format)",
            parser: :string,
            required: false
          ]
        ],
        flags: [
          verbose: [
            short: "-v",
            long: "--verbose",
            help: "Print detailed information during processing"
          ]
        ]
      )

    Optimus.parse!(optimus, args)
  end
end
