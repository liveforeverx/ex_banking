defmodule ExBanking.User.Registry do
  @moduledoc """
  Registry
  """

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  def start_link(_opts) do
    Registry.start_link(keys: :unique, name: __MODULE__)
  end
end
