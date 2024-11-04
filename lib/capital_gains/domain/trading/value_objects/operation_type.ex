defmodule CapitalGains.Domain.Trading.ValueObjects.OperationType do
  @moduledoc """
  Value object representing stock market operation types.

  This module encapsulates the concept of operation types in the stock market
  domain. It ensures that only valid operation types (buy/sell) can be created
  and used in the system.

  ## Operation Types

  1. Buy Operations (:buy)
     - Represent stock purchases
     - Increase portfolio position
     - Affect weighted average price

  2. Sell Operations (:sell)
     - Represent stock sales
     - Decrease portfolio position
     - Generate tax calculations

  ## Validation Rules

  - Only "buy" or "sell" strings are accepted
  - Case sensitive validation
  - No other operation types allowed

  ## Examples

  ```elixir
  # Valid operations
  OperationType.new("buy")   #=> {:ok, :buy}
  OperationType.new("sell")  #=> {:ok, :sell}

  # Invalid operations
  OperationType.new("SELL")  #=> {:error, :invalid_operation_type}
  OperationType.new("hold")  #=> {:error, :invalid_operation_type}
  ```

  ## Domain Rules

  1. Operation types are immutable
  2. Operation types affect portfolio calculations
  3. Operation types determine tax calculation flows
  4. Invalid operations must be rejected early
  """

  alias CapitalGains.Domain.Shared.Result

  @type t :: :buy | :sell

  def new("buy"), do: Result.ok(:buy)
  def new("sell"), do: Result.ok(:sell)
  def new(_), do: Result.error(:invalid_operation_type)
end
