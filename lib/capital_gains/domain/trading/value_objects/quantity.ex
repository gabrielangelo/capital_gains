defmodule CapitalGains.Domain.Trading.ValueObjects.Quantity do
  @moduledoc """
  Value object representing stock quantities in trading operations.

  This module ensures that stock quantities are always valid according to
  domain rules. It handles validation and provides a safe way to work with
  stock quantities throughout the system.

  ## Domain Rules

  1. Quantities must be positive integers
  2. Zero quantities are not allowed
  3. Fractional shares are not supported
  4. Maximum quantity is system dependent

  ## Validation Rules

  - Must be an integer
  - Must be greater than zero
  - Must not be fractional
  - Must not be nil

  ## Examples

  ```elixir
  # Valid quantities
  Quantity.new(100)   #=> {:ok, 100}
  Quantity.new(1)     #=> {:ok, 1}

  # Invalid quantities
  Quantity.new(0)     #=> {:error, :invalid_quantity}
  Quantity.new(-1)    #=> {:error, :invalid_quantity}
  Quantity.new(1.5)   #=> {:error, :invalid_quantity}
  ```

  ## Usage in Operations

  Quantities are used in:
  1. Buy operations - Adding to position
  2. Sell operations - Reducing position
  3. Weighted average calculations
  4. Position validation

  ## Safety Guarantees

  1. No negative quantities
  2. No zero quantities
  3. Always whole numbers
  4. Type safety in operations
  """

  alias CapitalGains.Domain.Shared.Result

  @type t :: pos_integer()

  def new(quantity) when is_integer(quantity) and quantity > 0 do
    Result.ok(quantity)
  end

  def new(_), do: Result.error(:invalid_quantity)
end
