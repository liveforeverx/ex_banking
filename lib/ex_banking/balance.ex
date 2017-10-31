defmodule ExBanking.Balance do
  @moduledoc """
  Balance handling functions, which abstracts precisions. Internally is uses representation as
  100 for 1 and handles all operations with integers. But as probably expected it returns back
  float. I would handle it differently in real world app.
  """

  @doc """
  Create new empty balance
  """
  def new() do
    %{}
  end

  @doc """
  Read amount of money in a currency.
  """
  def read(balance, currency) do
    amount = balance[currency] || 0
    amount / 100
  end

  @doc """
  Modify amount of money in a specific currency.
  """
  def modify(balance, currency, amount) do
    actual = balance[currency] || 0
    new = actual + number2fin(amount)

    cond do
      new < 0 -> {:error, :not_enough}
      true -> {:ok, Map.put(balance, currency, new), new / 100}
    end
  end

  defp number2fin(amount) do
    trunc(amount * 100)
  end
end
