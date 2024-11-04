defmodule CapitalGains.Domain.Trading.Entities.Portfolio do
  @moduledoc """
  A sophisticated entity representing a stock portfolio that manages positions and implements
  the complex logic of weighted average price calculations according to Brazilian market rules.
  This entity serves as the core domain model for tracking stock positions and their valuations,
  ensuring that all position changes and price calculations strictly follow market regulations.

  The Portfolio entity maintains the current position and weighted average price of stocks,
  implementing the specific Brazilian market rules for average price calculation. It handles
  both buy and sell operations, ensuring that the weighted average is correctly updated on
  purchases while being maintained during sales. The implementation guarantees that no invalid
  states can occur, such as negative positions or incorrect average calculations.

  The entity's immutable design ensures thread safety and maintains a clear history of state
  changes, while its strict validation rules prevent any illegal operations from being processed.
  It uses the Money value object for all price-related calculations,
  ensuring precise arithmetic without floating-point errors.

  # Use Cases

  ```elixir
  # Create a new portfolio
  portfolio = Portfolio.new()

  # Execute a buy operation
  buy_operation = StockOperation.new(%{
    "operation" => "buy",
    "unit-cost" => 10.00,
    "quantity" => 100
  })
  {:ok, portfolio} = Portfolio.execute_buy(portfolio, buy_operation)

  # Execute a sell operation
  sell_operation = StockOperation.new(%{
    "operation" => "sell",
    "unit-cost" => 15.00,
    "quantity" => 50
  })
  {:ok, portfolio} = Portfolio.execute_sell(portfolio, sell_operation)
  ```
  """

  alias CapitalGains.Domain.Shared.Result
  alias CapitalGains.Domain.Tax.ValueObjects.Money
  alias CapitalGains.Domain.Trading.Entities.StockOperation

  @type t :: %__MODULE__{
          position: non_neg_integer(),
          weighted_average: Money.t()
        }

  defstruct [:position, :weighted_average]

  @spec new() :: t()
  def new do
    {:ok, money} = Money.new(0.0)

    %__MODULE__{
      position: 0,
      weighted_average: money
    }
  end

  @spec execute_buy(t(), StockOperation.t()) :: Result.t(t())
  def execute_buy(portfolio, %StockOperation{type: :buy} = operation) do
    new_position = portfolio.position + operation.quantity
    new_average = calculate_weighted_average(portfolio, operation)

    Result.ok(%__MODULE__{
      position: new_position,
      weighted_average: new_average
    })
  end

  @spec execute_sell(t(), StockOperation.t()) :: Result.t(t())
  def execute_sell(portfolio, %StockOperation{type: :sell} = operation) do
    if portfolio.position >= operation.quantity do
      Result.ok(%__MODULE__{
        position: portfolio.position - operation.quantity,
        weighted_average: portfolio.weighted_average
      })
    else
      Result.error(:insufficient_position)
    end
  end

  @spec calculate_weighted_average(t(), StockOperation.t()) :: Money.t()
  defp calculate_weighted_average(%__MODULE__{position: 0}, operation) do
    operation.unit_cost
  end

  defp calculate_weighted_average(portfolio, operation) do
    current_value = Money.multiply(portfolio.weighted_average, portfolio.position)
    additional_value = Money.multiply(operation.unit_cost, operation.quantity)
    total_quantity = portfolio.position + operation.quantity

    %Money{
      amount_cents:
        div(
          current_value.amount_cents + additional_value.amount_cents,
          total_quantity
        )
    }
  end
end
