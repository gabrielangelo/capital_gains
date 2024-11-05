defmodule CapitalGains.Infrastructure.CLITest do
  @moduledoc false

  use ExUnit.Case, async: true
  alias CapitalGains.Infrastructure.CLI

  import ExUnit.CaptureIO

  describe "process_stdin/0" do
    test "processes single buy operation" do
      input = """
      [{"operation":"buy", "unit-cost":10.00, "quantity": 100}]
      """

      output =
        capture_io([input: input, capture_prompt: false], fn ->
          CLI.process_stdin()
        end)

      parsed = Poison.decode!(String.trim(output))
      assert parsed == [%{"tax" => 0.00}]
    end
  end

  test "processes multiple operations in same line" do
    input = """
    [{"operation":"buy", "unit-cost":10.00, "quantity": 100},{"operation":"sell", "unit-cost":15.00, "quantity": 50}]
    """

    output =
      capture_io([input: input, capture_prompt: false], fn ->
        CLI.process_stdin()
      end)

    parsed = Poison.decode!(String.trim(output))
    assert parsed == [%{"tax" => 0.00}, %{"tax" => 0.00}]
  end

  test "processes multiple lines independently" do
    input = """
    [{"operation":"buy", "unit-cost":10.00, "quantity": 100},{"operation":"sell", "unit-cost":15.00, "quantity": 50}]
    [{"operation":"buy", "unit-cost":10.00, "quantity": 10000},{"operation":"sell", "unit-cost":20.00, "quantity": 5000}]
    """

    output =
      capture_io([input: input, capture_prompt: false], fn ->
        CLI.process_stdin()
      end)

    lines =
      output
      |> String.trim()
      |> String.split("\n")
      |> Enum.map(&Poison.decode!/1)

    assert length(lines) == 2
    [first_line, second_line] = lines
    assert first_line == [%{"tax" => 0.00}, %{"tax" => 0.00}]
    assert second_line == [%{"tax" => 0.00}, %{"tax" => 10000.00}]
  end

  test "handles empty input" do
    output =
      capture_io([input: "\n", capture_prompt: false], fn ->
        CLI.process_stdin()
      end)

    assert String.trim(output) == ""
  end

  test "handles invalid JSON format" do
    input = """
    invalid json
    """

    output =
      capture_io([input: input, capture_prompt: false], fn ->
        CLI.process_stdin()
      end)

    parsed = Poison.decode!(String.trim(output))
    assert parsed == %{"error" => "Invalid JSON format"}
  end
end
