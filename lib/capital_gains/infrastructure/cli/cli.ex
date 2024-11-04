defmodule CapitalGains.Infrastructure.CLI do
  @moduledoc """
  Command-line interface for the Capital Gains Tax Calculator.

  This module provides two main interfaces:
  1. A command-line interface for the compiled escript (main/1)
  2. A testing interface for direct stdin processing (process_stdin/0)

  The CLI supports both file input and standard input, with options for:
  - Reading from a JSON file (-f, --file)
  - Verbose output (-v, --verbose)
  - Help and version information

  Example usage:
  ```bash
  # Process from stdin
  cat operations.json | capital_gains

  # Process from file
  capital_gains -f operations.json

  # Show help
  capital_gains --help
  ```

  For testing purposes, the module provides a simpler interface that reads
  directly from stdin without requiring command-line arguments.
  """

  alias CapitalGains.Application.OperationProcessor
  alias CapitalGains.Infrastructure.Cli.CliArgParser

  @doc """
  Main entry point for the escript executable.
  Handles command-line arguments and routes to appropriate processing functions.

  ## Parameters
    * `args` - List of command-line arguments

  ## Returns
    * Exits with status code 0 on success
    * Exits with status code 1 on error
  """
  @spec main(list(String.t())) :: no_return()
  def main(args) do
    args
    |> CliArgParser.parse_args()
    |> process_args()
  end

  @doc """
  Testing interface that processes input directly from stdin.
  This function is primarily used for testing purposes and provides
  a simpler interface without command-line argument handling.

  ## Returns
    * `:ok`
  """
  @spec process_stdin() :: :ok
  def process_stdin do
    IO.stream(:stdio, :line)
    |> Stream.map(&String.trim/1)
    |> Stream.reject(&(&1 == ""))
    |> process_input_stream()
  end

  @spec process_args(Optimus.ParseResult.t()) :: no_return()
  defp process_args(parsed) do
    try do
      case parsed.options.file do
        nil ->
          if parsed.flags.verbose, do: IO.puts("Reading from stdin...")
          process_stdin()

        file ->
          if parsed.flags.verbose, do: IO.puts("Reading from file: #{file}")
          process_file(file)
      end

      System.halt(0)
    rescue
      e in File.Error ->
        IO.puts(:stderr, "File error: #{e.message}")
        System.halt(1)

      e in Jason.DecodeError ->
        IO.puts(:stderr, "JSON error: #{e.message}")
        System.halt(1)

      _ ->
        IO.puts(:stderr, "Unexpected error occurred")
        System.halt(1)
    end
  end

  @spec process_file(String.t()) :: :ok
  def process_file(file) do
    case File.read(file) do
      {:ok, content} ->
        content
        |> String.split("\n")
        |> Stream.map(&String.trim/1)
        |> Stream.reject(&(&1 == ""))
        |> process_input_stream()

      {:error, reason} ->
        IO.puts(:stderr, "Error reading file: #{reason}")
        System.halt(1)
    end
  end

  @spec process_input_stream(Enumerable.t()) :: :ok
  def process_input_stream(stream) do
    stream
    |> Stream.map(&process_line/1)
    |> Stream.map(&encode_output/1)
    |> Stream.each(&IO.puts/1)
    |> Stream.run()
  end

  @spec process_line(String.t()) :: {:ok, map()} | {:error, String.t()}
  def process_line(line) do
    case Jason.decode(line) do
      {:ok, operations} ->
        case OperationProcessor.process_operations(operations) do
          {:error, reason} when is_atom(reason) ->
            {:error, Atom.to_string(reason)}

          result ->
            {:ok, result}
        end

      {:error, %Jason.DecodeError{}} ->
        {:error, "Invalid JSON format"}
    end
  end

  @spec encode_output({:ok, map()} | {:error, String.t()}) :: String.t()
  def encode_output({:ok, result}) do
    Jason.encode!(result)
  end

  def encode_output({:error, message}) do
    Jason.encode!(%{"error" => message})
  end
end
