defmodule CapitalGains.Domain.Trading.Entities.PortfolioTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias CapitalGains.Domain.Tax.ValueObjects.Money
  alias CapitalGains.Domain.Trading.Entities.Portfolio
  alias CapitalGains.Domain.Trading.Entities.StockOperation

  setup do
    {:ok, portfolio: Portfolio.new()}
  end

  def convert_float_to_decimal(value) do
    value
    |> Decimal.from_float()
    |> Decimal.round(2)
  end

  describe "weighted average calculation" do
    test "calculates correctly for first purchase", %{portfolio: portfolio} do
      {:ok, operation} = create_buy_operation(10.00, 100)
      {:ok, updated} = Portfolio.execute_buy(portfolio, operation)

      assert Decimal.equal?(
               Money.to_decimal(updated.weighted_average),
               convert_float_to_decimal(10.00)
             )
    end

    test "calculates weighted average after multiple purchases", %{portfolio: portfolio} do
      {:ok, op1} = create_buy_operation(10.00, 10)
      {:ok, op2} = create_buy_operation(20.00, 5)

      {:ok, updated} = Portfolio.execute_buy(portfolio, op1)
      {:ok, updated} = Portfolio.execute_buy(updated, op2)

      # ((10 * 10.00) + (5 * 20.00)) / 15 = 13.33
      assert Decimal.equal?(
               Money.to_decimal(updated.weighted_average),
               convert_float_to_decimal(13.33)
             )
    end
  end

  describe "position tracking" do
    test "updates position after buy", %{portfolio: portfolio} do
      {:ok, operation} = create_buy_operation(10.00, 100)
      {:ok, updated} = Portfolio.execute_buy(portfolio, operation)

      assert updated.position == 100
    end

    test "updates position after sell", %{portfolio: portfolio} do
      {:ok, buy_op} = create_buy_operation(10.00, 100)
      {:ok, sell_op} = create_sell_operation(15.00, 50)

      {:ok, updated} = Portfolio.execute_buy(portfolio, buy_op)
      {:ok, updated} = Portfolio.execute_sell(updated, sell_op)

      assert updated.position == 50
    end

    test "prevents selling more than owned", %{portfolio: portfolio} do
      {:ok, buy_op} = create_buy_operation(10.00, 100)
      {:ok, sell_op} = create_sell_operation(15.00, 150)

      {:ok, updated} = Portfolio.execute_buy(portfolio, buy_op)
      assert {:error, :insufficient_position} = Portfolio.execute_sell(updated, sell_op)
    end
  end

  describe "tax calculation scenarios" do
    test "handles operation below threshold", %{portfolio: portfolio} do
      {:ok, buy_op} = create_buy_operation(10.00, 100)
      {:ok, sell_op} = create_sell_operation(15.00, 50)

      {:ok, updated} = Portfolio.execute_buy(portfolio, buy_op)
      {:ok, updated} = Portfolio.execute_sell(updated, sell_op)

      assert updated.position == 50

      assert Decimal.equal?(
               Money.to_decimal(updated.weighted_average),
               convert_float_to_decimal(10.00)
             )
    end

    test "maintains weighted average after sales", %{portfolio: portfolio} do
      {:ok, buy_op} = create_buy_operation(10.00, 100)
      {:ok, sell_op} = create_sell_operation(20.00, 50)

      {:ok, updated} = Portfolio.execute_buy(portfolio, buy_op)
      {:ok, updated} = Portfolio.execute_sell(updated, sell_op)

      # Weighted average should remain the same after sales
      assert Money.to_decimal(updated.weighted_average) == convert_float_to_decimal(10.00)

      assert Decimal.equal?(
               Money.to_decimal(updated.weighted_average),
               convert_float_to_decimal(10.00)
             )
    end
  end

  defp create_operation(type, unit_cost, quantity) do
    StockOperation.new(%{
      "operation" => type,
      "unit-cost" => unit_cost,
      "quantity" => quantity
    })
  end

  defp create_buy_operation(unit_cost, quantity) do
    create_operation("buy", unit_cost, quantity)
  end

  defp create_sell_operation(unit_cost, quantity) do
    create_operation("sell", unit_cost, quantity)
  end
end
