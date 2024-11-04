defmodule CapitalGains.Domain.Shared.ResultTest do
  @moduledoc false

  use ExUnit.Case, async: true
  alias CapitalGains.Domain.Shared.Result

  describe "ok/1" do
    test "wraps primitive values" do
      assert Result.ok(42) == {:ok, 42}
      assert Result.ok("string") == {:ok, "string"}
      assert Result.ok(true) == {:ok, true}
      assert Result.ok(3.14) == {:ok, 3.14}
    end

    test "wraps complex data structures" do
      assert Result.ok([1, 2, 3]) == {:ok, [1, 2, 3]}
      assert Result.ok(%{key: "value"}) == {:ok, %{key: "value"}}
      assert Result.ok({:tuple, "value"}) == {:ok, {:tuple, "value"}}
    end

    test "wraps nil" do
      assert Result.ok(nil) == {:ok, nil}
    end

    test "preserves nested results" do
      assert Result.ok({:ok, 42}) == {:ok, {:ok, 42}}
      assert Result.ok({:error, "reason"}) == {:ok, {:error, "reason"}}
    end
  end

  describe "error/1" do
    test "wraps error atoms" do
      assert Result.error(:not_found) == {:error, :not_found}
      assert Result.error(:invalid_input) == {:error, :invalid_input}
    end

    test "wraps error strings" do
      assert Result.error("Something went wrong") == {:error, "Something went wrong"}
      assert Result.error("Invalid format") == {:error, "Invalid format"}
    end

    test "wraps complex error data" do
      error_data = %{code: 500, message: "Server error"}
      assert Result.error(error_data) == {:error, error_data}
    end

    test "wraps nil as error" do
      assert Result.error(nil) == {:error, nil}
    end
  end

  describe "map/2" do
    test "applies function to successful value" do
      assert Result.ok(2)
             |> Result.map(&(&1 * 2)) == {:ok, 4}
    end

    test "chains multiple transformations" do
      result =
        Result.ok(2)
        |> Result.map(&(&1 * 2))
        |> Result.map(&(&1 + 1))
        |> Result.map(&to_string/1)

      assert result == {:ok, "5"}
    end

    test "skips function for error results" do
      assert Result.error(:not_found)
             |> Result.map(&(&1 * 2)) == {:error, :not_found}
    end

    test "preserves error through multiple transformations" do
      result =
        Result.error("initial error")
        |> Result.map(&(&1 * 2))
        |> Result.map(&(&1 + 1))
        |> Result.map(&to_string/1)

      assert result == {:error, "initial error"}
    end

    test "handles functions that might raise" do
      result =
        Result.ok([1, 2, 3])
        |> Result.map(&Enum.sum/1)

      assert result == {:ok, 6}
    end

    test "works with capture syntax" do
      assert Result.ok("42")
             |> Result.map(&String.to_integer/1) == {:ok, 42}
    end
  end

  describe "complex transformations" do
    test "handles list operations" do
      result =
        Result.ok([1, 2, 3, 4, 5])
        |> Result.map(&Enum.filter(&1, fn x -> rem(x, 2) == 0 end))
        |> Result.map(&Enum.sum/1)

      assert result == {:ok, 6}
    end

    test "handles map transformations" do
      result =
        Result.ok(%{a: 1, b: 2})
        |> Result.map(&Map.values/1)
        |> Result.map(&Enum.sum/1)

      assert result == {:ok, 3}
    end

    test "handles string transformations" do
      result =
        Result.ok("hello")
        |> Result.map(&String.upcase/1)
        |> Result.map(&String.length/1)

      assert result == {:ok, 5}
    end
  end

  describe "edge cases" do
    test "handles empty collections" do
      assert Result.ok([])
             |> Result.map(&Enum.sum/1) == {:ok, 0}
    end

    test "handles whitespace strings" do
      assert Result.ok("   ")
             |> Result.map(&String.trim/1)
             |> Result.map(&String.length/1) == {:ok, 0}
    end

    test "preserves function errors" do
      assert Result.error({:function_error, :badarg})
             |> Result.map(&Enum.sum/1) == {:error, {:function_error, :badarg}}
    end
  end

  describe "domain specific examples" do
    test "money calculations" do
      result =
        Result.ok(10.50)
        |> Result.map(&(&1 * 100))
        |> Result.map(&trunc/1)

      assert result == {:ok, 1050}
    end

    test "tax calculations" do
      calculate_tax = fn amount -> amount * 0.2 end

      result =
        Result.ok(1000.00)
        |> Result.map(calculate_tax)

      assert result == {:ok, 200.00}
    end

    test "validation chain" do
      validate_positive = fn
        x when is_number(x) and x > 0 -> x
        _ -> throw(:invalid_number)
      end

      result =
        Result.ok(42)
        |> Result.map(validate_positive)

      assert result == {:ok, 42}
    end
  end

  describe "property-based examples" do
    test "map with identity function preserves value" do
      value = 42
      assert Result.ok(value) |> Result.map(& &1) == {:ok, value}
    end

    test "mapping over error is identity" do
      error = {:error, "reason"}
      assert Result.map(error, fn _ -> :something_else end) == error
    end

    test "composition of maps" do
      f = fn x -> x * 2 end
      g = fn x -> x + 1 end

      direct_result =
        Result.ok(42)
        |> Result.map(f)
        |> Result.map(g)

      composed_result =
        Result.ok(42)
        |> Result.map(fn x -> g.(f.(x)) end)

      assert direct_result == composed_result
    end
  end
end
