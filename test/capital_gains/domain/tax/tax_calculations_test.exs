defmodule CapitalGains.Domain.Tax.Entities.TaxCalculationTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias CapitalGains.Domain.Tax.Entities.TaxCalculation
  alias CapitalGains.Domain.Tax.ValueObjects.Money
  alias CapitalGains.Domain.Trading.Entities.Portfolio
  alias CapitalGains.Domain.Trading.Entities.StockOperation

  # Helper functions
  defp money(amount_in_cents), do: %Money{amount_cents: amount_in_cents}

  defp create_operation(type, unit_cost, quantity) do
    {:ok, op} =
      StockOperation.new(%{
        "operation" => type,
        "unit-cost" => unit_cost,
        "quantity" => quantity
      })

    op
  end

  defp create_portfolio(avg_price, position) do
    %Portfolio{
      weighted_average: money(avg_price * 100),
      position: position
    }
  end

  defp assert_tax_result(result, expected_tax_cents, expected_loss_cents) do
    assert {:ok, tax_result} = result
    assert tax_result.tax.amount_cents == expected_tax_cents
    assert tax_result.remaining_loss.amount_cents == expected_loss_cents
  end

  describe "calculate/3 with no previous losses" do
    setup do
      # Larger position
      portfolio = create_portfolio(10.00, 5000)
      no_loss = money(0)
      {:ok, portfolio: portfolio, no_loss: no_loss}
    end

    test "calculates tax for profitable operation above threshold", %{
      portfolio: portfolio,
      no_loss: no_loss
    } do
      # Operation total: 30.00 * 1000 = 30,000.00 (above threshold)
      operation = create_operation("sell", 30.00, 1000)
      result = TaxCalculation.calculate(operation, portfolio, no_loss)

      # Profit = (30 - 10) * 1000 = 20,000.00
      # Tax = 20,000 * 0.20 = 4,000.00 = 400,000 cents
      assert_tax_result(result, 400_000, 0)
    end

    test "no tax when operation is below threshold", %{portfolio: portfolio, no_loss: no_loss} do
      # Total: 1,500.00
      operation = create_operation("sell", 15.00, 100)
      result = TaxCalculation.calculate(operation, portfolio, no_loss)

      assert_tax_result(result, 0, 0)
    end

    test "no tax but accumulates loss when selling below average", %{
      portfolio: portfolio,
      no_loss: no_loss
    } do
      operation = create_operation("sell", 5.00, 100)
      result = TaxCalculation.calculate(operation, portfolio, no_loss)

      # Loss = (10 - 5) * 100 = 500.00
      assert_tax_result(result, 0, 50_000)
    end
  end

  describe "calculate/3 with previous losses" do
    setup do
      portfolio = create_portfolio(10.00, 5000)
      previous_loss = money(100_000)
      {:ok, portfolio: portfolio, loss: previous_loss}
    end

    test "deducts previous loss from profit before tax", %{portfolio: portfolio, loss: loss} do
      # Operation total: 30.00 * 1000 = 30,000.00 (above threshold)
      operation = create_operation("sell", 30.00, 1000)
      result = TaxCalculation.calculate(operation, portfolio, loss)

      # Profit = (30 - 10) * 1000 = 20,000.00
      # Net profit after loss = 20,000 - 1,000 = 19,000.00
      # Tax = 19,000 * 0.20 = 3,800.00 = 380,000 cents
      assert_tax_result(result, 380_000, 0)
    end

    test "accumulates additional losses", %{portfolio: portfolio, loss: loss} do
      operation = create_operation("sell", 5.00, 100)
      result = TaxCalculation.calculate(operation, portfolio, loss)

      # New loss = (10 - 5) * 100 = 500.00
      # Total loss = 1,000 + 500 = 1,500.00
      assert_tax_result(result, 0, 150_000)
    end

    test "handles partial loss deduction", %{portfolio: portfolio, loss: loss} do
      # Operation total: 40.00 * 1000 = 40,000.00 (above threshold)
      operation = create_operation("sell", 40.00, 1000)
      result = TaxCalculation.calculate(operation, portfolio, loss)

      # Profit = (40 - 10) * 1000 = 30,000.00
      # Net profit after loss = 30,000 - 1,000 = 29,000.00
      # Tax = 29,000 * 0.20 = 5,800.00 = 580,000 cents
      assert_tax_result(result, 580_000, 0)
    end
  end

  describe "calculate/3 threshold cases" do
    setup do
      portfolio = create_portfolio(10.00, 10_000)
      no_loss = money(0)
      {:ok, portfolio: portfolio, no_loss: no_loss}
    end

    test "exactly at threshold", %{portfolio: portfolio, no_loss: no_loss} do
      # 20.00 * 1000 = 20,000.00 (exactly at threshold)
      operation = create_operation("sell", 20.00, 1000)
      result = TaxCalculation.calculate(operation, portfolio, no_loss)

      assert_tax_result(result, 0, 0)
    end

    test "just above threshold", %{portfolio: portfolio, no_loss: no_loss} do
      # 20.01 * 1000 = 20,010.00 (just above threshold)
      operation = create_operation("sell", 20.01, 1000)
      result = TaxCalculation.calculate(operation, portfolio, no_loss)

      # Profit = (20.01 - 10) * 1000 = 10,010.00
      # Tax = 10,010 * 0.20 = 2,002.00 = 200,200 cents
      assert_tax_result(result, 200_200, 0)
    end

    test "just below threshold", %{portfolio: portfolio, no_loss: no_loss} do
      # 19.99 * 1000 = 19,990.00 (below threshold)
      operation = create_operation("sell", 19.99, 1000)
      result = TaxCalculation.calculate(operation, portfolio, no_loss)

      assert_tax_result(result, 0, 0)
    end
  end

  describe "calculate/3 edge cases" do
    setup do
      portfolio = create_portfolio(10.00, 1000)
      no_loss = money(0)
      {:ok, portfolio: portfolio, no_loss: no_loss}
    end

    test "selling at exact average price", %{portfolio: portfolio, no_loss: no_loss} do
      operation = create_operation("sell", 10.00, 100)
      result = TaxCalculation.calculate(operation, portfolio, no_loss)

      assert_tax_result(result, 0, 0)
    end

    test "handles high quantity operations", %{portfolio: portfolio, no_loss: no_loss} do
      operation = create_operation("sell", 15.00, 1_000_000)
      result = TaxCalculation.calculate(operation, portfolio, no_loss)

      {:ok, tax_result} = result
      assert tax_result.tax.amount_cents > 0
    end

    test "handles small price differences", %{portfolio: portfolio, no_loss: no_loss} do
      operation = create_operation("sell", 10.01, 100)
      result = TaxCalculation.calculate(operation, portfolio, no_loss)

      # Below threshold
      assert_tax_result(result, 0, 0)
    end
  end
end
