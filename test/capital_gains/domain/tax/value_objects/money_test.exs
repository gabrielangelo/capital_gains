defmodule CapitalGains.Domain.Tax.ValueObjects.MoneyTest do
  @moduledoc false

  use ExUnit.Case, async: true
  alias CapitalGains.Domain.Tax.ValueObjects.Money

  describe "new/1" do
    test "creates valid money value" do
      assert {:ok, money} = Money.new(100.50)
      assert money.amount_cents == 10_050
    end

    test "rejects negative values" do
      assert {:error, :invalid_money_amount} = Money.new(-10.00)
    end
  end

  describe "add/2" do
    test "sum two values" do
      assert {:ok, money} = Money.new(100.50)
      assert {:ok, money_2} = Money.new(100.50)
      new_money = Money.add(money, money_2)
      assert new_money.amount_cents == 20_100
    end
  end

  describe "to_float/1" do
    test "converts cents to float with proper precision" do
      {:ok, money} = Money.new(100.55)
      assert Decimal.equal?(Money.to_decimal(money), Decimal.from_float(100.55))
    end
  end
end
