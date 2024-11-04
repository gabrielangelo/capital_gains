defmodule CapitalGains.Application.OperationProcessorTest do
  @moduledoc false
  use ExUnit.Case, async: true
  alias CapitalGains.Application.OperationProcessor

  # Helper functions
  defp create_operation(type, unit_cost, quantity) do
    %{"operation" => type, "unit-cost" => unit_cost, "quantity" => quantity}
  end

  defp create_tax_result(amount) do
    %{"tax" => Decimal.new(amount) |> Decimal.round(2)}
  end

  defp create_zero_tax do
    create_tax_result(0)
  end

  describe "Document test cases" do
    test "case 1 - operations below threshold" do
      operations = [
        create_operation("buy", 10.00, 100),
        create_operation("sell", 15.00, 50),
        create_operation("sell", 15.00, 50)
      ]

      expected = List.duplicate(create_zero_tax(), 3)
      assert OperationProcessor.process_operations(operations) == expected
    end

    test "case 2 - profit and subsequent loss" do
      operations = [
        create_operation("buy", 10.00, 10_000),
        create_operation("sell", 20.00, 5_000),
        create_operation("sell", 5.00, 5_000)
      ]

      expected = [
        create_zero_tax(),
        create_tax_result(10_000),
        create_zero_tax()
      ]

      assert OperationProcessor.process_operations(operations) == expected
    end

    test "case 3 - loss deduction from future profits" do
      operations = [
        create_operation("buy", 10.00, 10_000),
        create_operation("sell", 5.00, 5_000),
        create_operation("sell", 20.00, 3_000)
      ]

      expected = [
        create_zero_tax(),
        create_zero_tax(),
        create_tax_result(1_000)
      ]

      assert OperationProcessor.process_operations(operations) == expected
    end

    test "case 4 - weighted average price calculation" do
      operations = [
        create_operation("buy", 10.00, 10_000),
        create_operation("buy", 25.00, 5_000),
        create_operation("sell", 15.00, 10_000)
      ]

      expected = List.duplicate(create_zero_tax(), 3)
      assert OperationProcessor.process_operations(operations) == expected
    end

    test "case 5 - weighted average with multiple operations" do
      operations = [
        create_operation("buy", 10.00, 10_000),
        create_operation("buy", 25.00, 5_000),
        create_operation("sell", 15.00, 10_000),
        create_operation("sell", 25.00, 5_000)
      ]

      expected = [
        create_zero_tax(),
        create_zero_tax(),
        create_zero_tax(),
        create_tax_result(10_000)
      ]

      assert OperationProcessor.process_operations(operations) == expected
    end

    test "case 6 - complex loss deduction scenario" do
      operations = [
        create_operation("buy", 10.00, 10_000),
        create_operation("sell", 2.00, 5_000),
        create_operation("sell", 20.00, 2_000),
        create_operation("sell", 20.00, 2_000),
        create_operation("sell", 25.00, 1_000)
      ]

      expected = [
        create_zero_tax(),
        create_zero_tax(),
        create_zero_tax(),
        create_zero_tax(),
        create_tax_result(3_000)
      ]

      assert OperationProcessor.process_operations(operations) == expected
    end

    test "case 7 - comprehensive scenario with multiple operations" do
      operations = [
        create_operation("buy", 10.00, 10_000),
        create_operation("sell", 2.00, 5_000),
        create_operation("sell", 20.00, 2_000),
        create_operation("sell", 20.00, 2_000),
        create_operation("sell", 25.00, 1_000),
        create_operation("buy", 20.00, 10_000),
        create_operation("sell", 15.00, 5_000),
        create_operation("sell", 30.00, 4_350),
        create_operation("sell", 30.00, 650)
      ]

      expected = [
        create_zero_tax(),
        create_zero_tax(),
        create_zero_tax(),
        create_zero_tax(),
        create_tax_result(3_000),
        create_zero_tax(),
        create_zero_tax(),
        create_tax_result(3_700),
        create_zero_tax()
      ]

      assert OperationProcessor.process_operations(operations) == expected
    end

    test "case 8 - high value operations" do
      operations = [
        create_operation("buy", 10.00, 10_000),
        create_operation("sell", 50.00, 10_000),
        create_operation("buy", 20.00, 10_000),
        create_operation("sell", 50.00, 10_000)
      ]

      expected = [
        create_zero_tax(),
        create_tax_result(80_000),
        create_zero_tax(),
        create_tax_result(60_000)
      ]

      assert OperationProcessor.process_operations(operations) == expected
    end
  end

  describe "error cases" do
    test "handles invalid operation type" do
      operations = [create_operation("invalid", 10.00, 100)]
      assert {:error, :invalid_operation_type} = OperationProcessor.process_operations(operations)
    end

    test "handles invalid quantity" do
      operations = [create_operation("buy", 10.00, -100)]
      assert {:error, :invalid_quantity} = OperationProcessor.process_operations(operations)
    end

    test "handles invalid unit cost" do
      operations = [create_operation("buy", -10.00, 100)]
      assert {:error, :invalid_money_amount} = OperationProcessor.process_operations(operations)
    end

    test "handles insufficient position for sale" do
      operations = [
        create_operation("buy", 10.00, 100),
        create_operation("sell", 15.00, 150)
      ]

      assert {:error, :insufficient_position} = OperationProcessor.process_operations(operations)
    end
  end
end
