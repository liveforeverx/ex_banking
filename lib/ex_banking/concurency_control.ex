defmodule ExBanking.ConcurencyControl do
  @moduledoc """
  Provides per entity concurency control.

  TODO: For production use, need clean up of names, which are .
  """
  use GenServer

  @table __MODULE__

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc false
  def init(_) do
    table = :ets.new(@table, [:named_table, :public, :set, {:keypos, 1}])
    {:ok, table}
  end

  @doc """
  Run operation, if there is not more than a limit of other operations on the same
  name.
  """
  def run(name, fun, limit \\ 10) do
    :ets.insert_new(@table, {name, 0})

    case :ets.update_counter(@table, name, [{2, 0}, {2, 1, limit, limit}]) do
      [counter, _] when counter < limit ->
        try do
          fun.()
        after
          :ets.update_counter(@table, name, [{2, -1, 0, 0}])
        end

      [limit, limit] ->
        {:error, :limit}
    end
  end
end
