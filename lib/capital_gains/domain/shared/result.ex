defmodule CapitalGains.Domain.Shared.Result do
  @moduledoc """
  A comprehensive Result monad implementation that provides a robust way to handle operations that may fail in a functional
   and composable manner. This module encapsulates the concept of a computation that may either succeed with a value
   or fail with an error, allowing for clean error propagation and handling throughout the application.
   By using this Result type, we can avoid raising exceptions for expected failure cases and maintain
   a clear separation between happy paths and error handling.

  The Result type follows the Railway Oriented Programming pattern, where success and failure cases
  are treated as separate tracks that can be composed and transformed in a type-safe way. This approach
  is particularly valuable in domain-driven design as it helps maintain invariants and ensures that error
  cases are handled explicitly rather than being overlooked.

  The implementation provides core operations like wrapping values in success/error contexts and mapping
  over successful results while preserving errors. This allows for building complex chains of operations where
  errors short-circuit the computation chain automatically, leading to more maintainable and predictable code.

  # Use Cases

  ```elixir
  # Basic success case
  iex> Result.ok(42)
  {:ok, 42}

  # Basic error case
  iex> Result.error(:invalid_input)
  {:error, :invalid_input}

  # Mapping over a success
  iex> Result.ok(2)
  ...> |> Result.map(&(&1 * 2))
  {:ok, 4}

  # Error propagation
  iex> Result.error(:not_found)
  ...> |> Result.map(&(&1 * 2))
  {:error, :not_found}

  # Complex chaining
  iex> Result.ok([1, 2, 3])
  ...> |> Result.map(&Enum.sum/1)
  ...> |> Result.map(&(&1 * 2))
  {:ok, 12}
  ```

  The module is particularly useful in our capital gains application for handling operations that might fail due to invalid inputs, insufficient positions, or calculation errors. It provides a consistent way to propagate these failures through the system while maintaining type safety and explicit error handling.
  """
  @type t(a) :: {:ok, a} | {:error, any()}

  @spec ok(any()) :: {:ok, any()}
  def ok(value), do: {:ok, value}

  @spec error(any()) :: {:error, any()}
  def error(reason), do: {:error, reason}

  @spec map(t(a), (a -> b)) :: t(b) when a: var, b: var
  def map({:ok, value}, func), do: {:ok, func.(value)}
  def map({:error, _} = error, _func), do: error
end
