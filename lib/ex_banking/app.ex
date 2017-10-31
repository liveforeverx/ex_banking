defmodule ExBanking.App do
  @moduledoc false

  alias ExBanking.{User, ConcurencyControl}
  use Application

  def start(_type, _args) do
    User.init_db()

    children = [
      ConcurencyControl
    ]

    opts = [strategy: :one_for_one, name: ExBanking.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
