defmodule CapitalGains.Infrastructure.CLI do
  @moduledoc """
  Command-line interface for the Capital Gains Tax Calculator.

  This module provides a streamlined interface for processing stock market operations
  and calculating capital gains taxes according to Brazilian rules. It processes
  operations from standard input (stdin), handling both single and multiple operations
  in JSON format.

  ## Architecture

  The module follows a stream-based processing approach with clear stages:
  1. Input Processing: Reads and validates JSON input
  2. Operation Processing: Calculates taxes for valid operations
  3. Output Formatting: Generates JSON responses
  """

  alias CapitalGains.Application.OperationProcessor

  @doc """
    Handles command-line stdin.
  """
  @spec main(term()) :: no_return()
  def main(_args) do
    process_stdin()
  end

  @spec process_stdin() :: :ok
  def process_stdin do
    IO.stream(:stdio, :line)
    |> Stream.map(&String.trim/1)
    |> Stream.reject(&(&1 == ""))
    |> process_input_stream()
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
    case Poison.decode(line) do
      {:ok, operations} ->
        case OperationProcessor.process_operations(operations) do
          {:error, reason} when is_atom(reason) ->
            {:error, Atom.to_string(reason)}

          result ->
            {:ok, result}
        end

      {:error, _} ->
        {:error, "Invalid JSON format"}
    end
  end

  @spec encode_output({:ok, map()} | {:error, String.t()}) :: String.t()
  def encode_output({:ok, result}) do
    Poison.encode!(result)
  end

  def encode_output({:error, message}) do
    Poison.encode!(%{"error" => message})
  end
end
