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

  @index 2

  @doc """
  Run operation, if there is not more than a limit of other operations on the same
  name.
  """
  def run(name, fun, limit \\ 10) do
    :ets.insert_new(@table, {name, 0})

    # Adding zero, will return the actual number of running elements
    get_counter = {@index, 0}
    # Set treshhold to limit, so by trashhold we still should set back to our limit
    increment = {@index, 1, limit, limit}

    case :ets.update_counter(@table, name, [get_counter, increment]) do
      [counter, _] when counter < limit ->
        try do
          fun.()
        after
          # Set trashhold to zero, so that if applied it wouldn't be less zero.
          # Should never happen anyway.
          decrement = {@index, -1, 0, 0}
          :ets.update_counter(@table, name, [decrement])
        end

      # In a case, we reached our limit, we should return error
      [^limit, ^limit] ->
        {:error, :limit}
    end
  end
end
