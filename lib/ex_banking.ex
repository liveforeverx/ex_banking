defmodule ExBanking do
  @moduledoc """
  Public interface for testing.

  TODO: Should be documented.
  """

  alias ExBanking.{Balance, User}

  @type banking_error :: {
          :error,
          :wrong_arguments
          | :user_already_exists
          | :user_does_not_exist
          | :not_enough_money
          | :sender_does_not_exist
          | :receiver_does_not_exist
          | :too_many_requests_to_user
          | :too_many_requests_to_sender
          | :too_many_requests_to_receiver
        }

  @spec create_user(user :: String.t()) :: :ok | banking_error
  def create_user(user) when is_binary(user) do
    case User.create(user) do
      {:error, {^user, :exists}} ->
        {:error, :user_already_exists}

      {:ok, _} ->
        :ok
    end
  end

  def create_user(_), do: {:error, :wrong_arguments}

  @spec deposit(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number} | banking_error
  def deposit(user, amount, currency)
      when is_binary(user) and is_number(amount) and amount > 0 and is_binary(currency) do
    single_transaction(user, &Balance.modify(&1, currency, amount))
  end

  def deposit(_user, _amount, _currency) do
    {:error, :wrong_arguments}
  end

  @spec withdraw(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number} | banking_error
  def withdraw(user, amount, currency)
      when is_binary(user) and is_number(amount) and amount > 0 and is_binary(currency) do
    single_transaction(user, &Balance.modify(&1, currency, -amount))
  end

  def withdraw(_user, _amount, _currency) do
    {:error, :wrong_arguments}
  end

  @spec get_balance(user :: String.t(), currency :: String.t()) ::
          {:ok, balance :: number} | banking_error
  def get_balance(user, currency) when is_binary(user) and is_binary(currency) do
    single_transaction(user, fn balance -> {:ok, balance, Balance.read(balance, currency)} end)
  end

  def get_balance(_user, _currency) do
    {:error, :wrong_arguments}
  end

  defp single_transaction(user, fun) do
    case User.transaction(fn -> User.on_balance(user, fun) end) do
      {:ok, new_balance} ->
        {:ok, new_balance}

      {:error, {^user, :not_enough}} ->
        {:error, :not_enough_money}

      {:error, {^user, :not_found}} ->
        {:error, :user_does_not_exist}

      {:error, {^user, :limit}} ->
        {:error, :too_many_requests_to_user}
    end
  end

  @spec send(
          from_user :: String.t(),
          to_user :: String.t(),
          amount :: number,
          currency :: String.t()
        ) :: {:ok, from_user_balance :: number, to_user_balance :: number} | banking_error
  def send(from_user, to_user, amount, currency)
      when is_binary(from_user) and is_binary(to_user) and is_number(amount) and amount > 0 and
             is_binary(currency) and from_user != to_user do
    transaction_result =
      User.transaction(fn ->
        from_balance = User.on_balance(from_user, &Balance.modify(&1, currency, -amount))
        to_user_balance = User.on_balance(to_user, &Balance.modify(&1, currency, amount))
        {from_balance, to_user_balance}
      end)

    case transaction_result do
      {:ok, {sender_balance, reciever_balance}} ->
        {:ok, sender_balance, reciever_balance}

      {:error, {^from_user, :not_enough}} ->
        {:error, :not_enough_money}

      {:error, {^from_user, :not_found}} ->
        {:error, :sender_does_not_exist}

      {:error, {^to_user, :not_found}} ->
        {:error, :receiver_does_not_exist}

      {:error, {^from_user, :limit}} ->
        {:error, :too_many_requests_to_sender}

      {:error, {^to_user, :limit}} ->
        {:error, :too_many_requests_to_receiver}
    end
  end

  def send(_from_user, _to_user, _amount, _currency) do
    {:error, :wrong_arguments}
  end
end
