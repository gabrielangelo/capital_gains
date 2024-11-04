defmodule CapitalGains.Domain.Shared.Errors do
  @moduledoc """
  Defines domain-specific error types for the application.

  This module provides a centralized place for error definitions used across
  the application. It helps maintain consistency in error handling and provides
  clear error types for different scenarios.
  """

  defmodule ValidationError do
    defexception [:message]
  end

  defmodule DomainError do
    defexception [:message]
  end
end
