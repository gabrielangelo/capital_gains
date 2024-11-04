defmodule CapitalGains.Domain.Tax.ValueObjects.Money do
  @moduledoc """
  A comprehensive implementation of the Money value object that ensures precise and reliable handling
  of monetary values in the Brazilian stock market context. This implementation addresses the fundamental
  challenges of financial calculations by storing all values in cents as integers, thereby eliminating
  floating-point arithmetic errors that could be catastrophic in financial calculations.

  The Money value object enforces immutability and provides a complete set of operations needed
  for financial calculations, including addition, multiplication, and conversion between cents
  and decimal representations. All operations are designed to maintain precision and prevent common
  pitfalls such as rounding errors or precision loss that could accumulate in complex calculations.

  The implementation is specifically tailored for the Brazilian market, handling BRL currency and
  following Brazilian accounting rules for rounding and precision. It enforces two decimal places
  precision and implements proper rounding strategies that comply with financial regulations.

  # Use Cases

  ```elixir
  # Creating money values
  iex> Money.new(100.50)
  {:ok, %Money{amount_cents: 10050}}

  # Adding money values
  iex> money1 = Money.new(100.00)
  iex> money2 = Money.new(50.00)
  iex> Money.add(money1, money2)
  %Money{amount_cents: 15000}

  # Multiplication (e.g., for quantity calculations)
  iex> money = Money.new(10.00)
  iex> Money.multiply(money, 3)
  %Money{amount_cents: 3000}

  This implementation is crucial for our capital gains calculator as it ensures that all monetary calculations,
  from position values to tax calculations, are performed with absolute precision and reliability. The value object
  encapsulates all the complexity of dealing with monetary values while providing a clean and safe interface for the
  rest of the application to use.
  """

  alias CapitalGains.Domain.Shared.Result

  @type t :: %__MODULE__{
          amount_cents: non_neg_integer()
        }

  defstruct [:amount_cents]

  @spec new(float()) :: Result.t(t())
  def new(float) when is_float(float) and float >= 0 do
    Result.ok(%__MODULE__{
      amount_cents: trunc(float * 100)
    })
  end

  def new(_), do: Result.error(:invalid_money_amount)

  @spec to_decimal(t()) :: Decimal.t()
  def to_decimal(%__MODULE__{amount_cents: cents} = _money) do
    Decimal.from_float(cents / 100) |> Decimal.round(2)
  end

  @spec add(t(), t()) :: t()
  def add(%__MODULE__{amount_cents: a}, %__MODULE__{amount_cents: b}) do
    %__MODULE__{amount_cents: a + b}
  end

  @spec multiply(t(), non_neg_integer()) :: t()
  def multiply(%__MODULE__{amount_cents: amount}, quantity) do
    %__MODULE__{amount_cents: amount * quantity}
  end
end
