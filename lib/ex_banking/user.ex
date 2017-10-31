defmodule ExBanking.User do
  @moduledoc """
  General user and associated balance handling with concurency limit control.
  Concurency limit enforced per user.
  """
  @table :users
  alias ExBanking.{Balance, ConcurencyControl}

  @doc false
  def init_db() do
    :mnesia.start()
    :mnesia.create_table(@table, [{:ram_copies, [node()]}, {:attributes, [:name, :balance]}])
  end

  @doc """
  Create user.
  """
  def create(name) do
    transaction(fn ->
      case :mnesia.read(@table, name, :write) do
        [] -> :mnesia.write({@table, name, Balance.new()})
        _ -> :mnesia.abort({name, :exists})
      end
    end)
  end

  @doc """
  Run transaction.
  """
  def transaction(fun) do
    case :mnesia.transaction(fun) do
      {:atomic, result} ->
        {:ok, result}

      {:aborted, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Run operation on user balance. Should be used inside of transaction.
  """
  def on_balance(name, fun, limit \\ 10) do
    with {:error, :limit} <-
           ConcurencyControl.run(name, fn -> do_on_balance(name, fun) end, limit) do
      :mnesia.abort({name, :limit})
    end
  end

  def do_on_balance(name, fun) do
    case :mnesia.read(@table, name, :write) do
      [] ->
        :mnesia.abort({name, :not_found})

      [{@table, ^name, balance}] ->
        case fun.(balance) do
          {:ok, balance, answer} ->
            :mnesia.write(@table, {@table, name, balance}, :write)
            answer

          {:error, error} ->
            :mnesia.abort({name, error})
        end
    end
  end
end
