defmodule CapitalGains.Domain.Trading.Entities.StockOperation do
  @moduledoc """
  A robust entity representing stock market operations that encapsulates the complete
  behavior and validation rules for buy and sell transactions in the Brazilian market.
  This entity serves as the fundamental building block for all trading operations,
  ensuring that each transaction is valid, properly typed, and contains all required information for processing.

  The StockOperation entity enforces strict validation rules on all its components, including operation type,
  quantity, and price. It uses value objects for these components to ensure that each piece of data
  is valid and properly formatted before an operation can be created. This approach prevents invalid
  operations from entering the system and provides clear error messages when validation fails.

  The implementation supports both buy and sell operations, with each type having its specific validation
  rules and behaviors. It works seamlessly with other domain entities like Portfolio and TaxCalculation
  to provide a complete representation of market operations.

  # Use Cases

  ```elixir
  # Create a buy operation
  {:ok, buy_operation} = StockOperation.new(%{
    "operation" => "buy",
    "unit-cost" => 10.00,
    "quantity" => 100
  })

  # Create a sell operation
  {:ok, sell_operation} = StockOperation.new(%{
    "operation" => "sell",
    "unit-cost" => 15.00,
    "quantity" => 50
  })

  # Calculate operation total
  total = StockOperation.operation_total(operation)
  ```
  """

  alias CapitalGains.Domain.Shared.Result

  alias CapitalGains.Domain.Trading.ValueObjects.OperationType
  alias CapitalGains.Domain.Trading.ValueObjects.Quantity

  alias CapitalGains.Domain.Tax.ValueObjects.Money

  @type t :: %__MODULE__{
          type: OperationType.t(),
          unit_cost: Money.t(),
          quantity: Quantity.t()
        }

  defstruct [:type, :unit_cost, :quantity]

  def new(params) do
    with {:ok, type} <- OperationType.new(params["operation"]),
         {:ok, quantity} <- Quantity.new(params["quantity"]),
         {:ok, unit_cost} <- Money.new(params["unit-cost"]) do
      Result.ok(%__MODULE__{
        type: type,
        unit_cost: unit_cost,
        quantity: quantity
      })
    end
  end

  def operation_total(%__MODULE__{unit_cost: cost, quantity: qty}) do
    Money.multiply(cost, qty)
  end
end
