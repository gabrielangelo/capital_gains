defmodule CapitalGains.Application.OperationProcessor do
  @moduledoc """
  A comprehensive application service that orchestrates the entire process
  of stock market operation processing and tax calculation. This module
  serves as the main coordinator between the trading and tax domains,
  implementing the complex workflow of processing operations, maintaining
  portfolio state, and calculating taxes.

  The processor implements a stateful approach where each operation affects
  the cumulative state of the portfolio and loss tracking, while ensuring
  that each input line of operations is processed independently.
  This design allows for batch processing of operations while maintaining
  isolation between different sets of operations, as required by the Brazilian tax system.

  The implementation carefully handles the edge cases in the tax calculation process,
  including operations below the tax threshold (R$ 20,000.00),
  loss accumulation and deduction, and weighted average price calculations.
  It maintains precision throughout all calculations by leveraging the Money value
  object and provides clear error handling through the Result monad.

  # Use Cases

  ```elixir
  # Process a simple buy and sell operation
  operations = [
    %{"operation" => "buy", "unit-cost" => 10.00, "quantity" => 100},
    %{"operation" => "sell", "unit-cost" => 15.00, "quantity" => 50}
  ]

  OperationProcessor.process_operations(operations)
  # => [%{"tax" => #Decimal<0.00>}, %{"tax" => #Decimal<0.00>}]

  # Process complex operations with loss deduction
  operations = [
    %{"operation" => "buy", "unit-cost" => 10.00, "quantity" => 10000},
    %{"operation" => "sell", "unit-cost" => 5.00, "quantity" => 5000},
    %{"operation" => "sell", "unit-cost" => 20.00, "quantity" => 3000}
  ]

  OperationProcessor.process_operations(operations)
  # => [%{"tax" => #Decimal<0.00>}, %{"tax" => #Decimal<0.00}, %{"tax" => 1000.00}]
  ```
  """
  alias CapitalGains.Domain.Shared.Result

  alias CapitalGains.Domain.Trading.Entities.Portfolio
  alias CapitalGains.Domain.Trading.Entities.StockOperation

  alias CapitalGains.Domain.Tax.Entities.TaxCalculation
  alias CapitalGains.Domain.Tax.ValueObjects.Money

  @type operation_input :: %{
          required(String.t()) => String.t() | number()
        }

  @type tax_result :: %{
          required(String.t()) => Decimal.t()
        }

  @spec process_operations([operation_input()]) ::
          [tax_result()] | {:error, atom()}
  def process_operations(operations) do
    initial_state = {
      Portfolio.new(),
      %Money{amount_cents: 0},
      []
    }

    operations
    |> Enum.reduce_while({:ok, initial_state}, &process_operation/2)
    |> format_results()
  end

  @spec process_operation(operation_input(), Result.t({Portfolio.t(), Money.t(), [Money.t()]})) ::
          {:cont, Result.t({Portfolio.t(), Money.t(), [Money.t()]})}
          | {:halt, {:error, atom()}}
  defp process_operation(operation_params, {:ok, state}) do
    with {:ok, operation} <- StockOperation.new(operation_params),
         {:ok, new_state} <- execute_operation(operation, state) do
      {:cont, {:ok, new_state}}
    else
      {:error, reason} -> {:halt, {:error, reason}}
    end
  end

  @spec execute_operation(StockOperation.t(), {Portfolio.t(), Money.t(), [Money.t()]}) ::
          Result.t({Portfolio.t(), Money.t(), [Money.t()]})
  defp execute_operation(%StockOperation{type: :buy} = op, {portfolio, loss, taxes}) do
    {:ok, new_portfolio} = Portfolio.execute_buy(portfolio, op)
    Result.ok({new_portfolio, loss, [%Money{amount_cents: 0} | taxes]})
  end

  defp execute_operation(%StockOperation{type: :sell} = op, {portfolio, loss, taxes}) do
    with {:ok, new_portfolio} <- Portfolio.execute_sell(portfolio, op),
         {:ok, tax_result} <- TaxCalculation.calculate(op, portfolio, loss) do
      Result.ok({
        new_portfolio,
        tax_result.remaining_loss,
        [tax_result.tax | taxes]
      })
    end
  end

  @spec format_results({:ok, {Portfolio.t(), Money.t(), [Money.t()]}} | {:error, atom()}) ::
          [tax_result()] | {:error, atom()}
  defp format_results({:ok, {_portfolio, _loss, taxes}}) do
    taxes
    |> Enum.reverse()
    |> Enum.map(&format_tax/1)
  end

  defp format_results({:error, reason}), do: {:error, reason}

  @spec format_tax(Money.t()) :: tax_result()
  defp format_tax(tax), do: %{"tax" => Money.to_decimal(tax)}
end
