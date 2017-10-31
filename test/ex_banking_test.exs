defmodule ExBankingTest do
  use ExUnit.Case
  doctest ExBanking

  test "basic test" do
    assert ExBanking.create_user("test") == :ok
    assert ExBanking.create_user("test") == {:error, :user_already_exists}
    assert ExBanking.deposit("not_exists", 10, "w") == {:error, :user_does_not_exist}
    assert ExBanking.deposit("test", 10, "w") == {:ok, 10.0}
    assert ExBanking.withdraw("test", 5, "w") == {:ok, 5.0}
    assert ExBanking.withdraw("test", 10, "w") == {:error, :not_enough_money}
    assert ExBanking.send("test", "test2", 2, "w") == {:error, :receiver_does_not_exist}
    assert ExBanking.send("test2", "test", 2, "w") == {:error, :sender_does_not_exist}
    assert ExBanking.create_user("test2") == :ok
    assert ExBanking.send("test", "test2", 10, "w") == {:error, :not_enough_money}
    assert ExBanking.send("test", "test2", 2, "w") == {:ok, 3.0, 2.0}
    assert ExBanking.get_balance("test2", "w") == {:ok, 2.0}
    assert ExBanking.get_balance("test2", "x") == {:ok, 0.0}
  end
end
