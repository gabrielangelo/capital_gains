defmodule CapitalGains.Domain.Tax.Entities.TaxCalculation do
  @moduledoc """
  A comprehensive implementation of Brazilian stock market tax calculations that
  encapsulates all rules and regulations for capital gains tax assessment. This
  entity handles the complex logic of determining taxable profits, managing loss
  carryforwards, and applying the appropriate tax rates according to Brazilian legislation.

  The implementation covers all aspects of Brazilian capital gains tax rules,
  including the 20% tax rate on profits, the R$ 20,000.00 tax threshold per operation,
  and the intricate rules for loss deduction. It maintains precise calculations through
  integer arithmetic and provides a clear audit trail of all tax determinations.

  The tax calculator carefully handles all special cases defined in Brazilian tax law,
  including operations below the threshold, accumulated losses from previous operations,
  and partial loss deductions. It works in conjunction with the Portfolio entity to
  determine accurate profit/loss calculations based on weighted average prices.

  # Use Cases

  ```elixir
  # Calculate tax for a profitable operation
  portfolio = Portfolio.new()
  |> Portfolio.execute_buy(%{unit-cost: 10.00, quantity: 1000})

  operation = StockOperation.new(%{
    "operation" => "sell",
    "unit-cost" => 15.00,
    "quantity" => 500
  })

  {:ok, tax_result} = TaxCalculation.calculate(operation, portfolio, accumulated_loss)

  # Calculate tax with loss deduction
  operation = StockOperation.new(%{
    "operation" => "sell",
    "unit-cost" => 20.00,
    "quantity" => 300
  })

  {:ok, tax_result} = TaxCalculation.calculate(operation, portfolio, previous_loss)
  ```
  """

  alias CapitalGains.Domain.Shared.Result
  alias CapitalGains.Domain.Tax.ValueObjects.Money

  alias CapitalGains.Domain.Trading.Entities.Portfolio
  alias CapitalGains.Domain.Trading.Entities.StockOperation

  @tax_threshold_cents 2_000_000
  @tax_rate_percent 20

  @type tax_result :: %{
          tax: Money.t(),
          remaining_loss: Money.t()
        }

  @spec calculate(StockOperation.t(), Portfolio.t(), Money.t()) :: Result.t(tax_result())
  def calculate(operation, portfolio, accumulated_loss) do
    operation_total = StockOperation.operation_total(operation)
    profit_or_loss = calculate_profit_or_loss(operation, portfolio)

    determine_tax(operation_total, profit_or_loss, accumulated_loss)
  end

  @spec calculate_profit_or_loss(StockOperation.t(), Portfolio.t()) :: Money.t()
  defp calculate_profit_or_loss(operation, portfolio) do
    sale_value = Money.multiply(operation.unit_cost, operation.quantity)
    cost_value = Money.multiply(portfolio.weighted_average, operation.quantity)

    %Money{
      amount_cents: sale_value.amount_cents - cost_value.amount_cents
    }
  end

  @spec determine_tax(Money.t(), Money.t(), Money.t()) :: Result.t(tax_result())
  defp determine_tax(_total, %Money{amount_cents: profit}, loss) when profit <= 0 do
    new_loss = Money.add(loss, %Money{amount_cents: abs(profit)})
    Result.ok(%{tax: %Money{amount_cents: 0}, remaining_loss: new_loss})
  end

  defp determine_tax(total, _profit, loss)
       when total.amount_cents <= @tax_threshold_cents do
    Result.ok(%{tax: %Money{amount_cents: 0}, remaining_loss: loss})
  end

  defp determine_tax(_total, profit, loss) do
    net_profit = max(profit.amount_cents - loss.amount_cents, 0)
    remaining_loss = max(loss.amount_cents - profit.amount_cents, 0)

    tax = trunc(net_profit * @tax_rate_percent / 100)

    Result.ok(%{
      tax: %Money{amount_cents: tax},
      remaining_loss: %Money{amount_cents: remaining_loss}
    })
  end
end
