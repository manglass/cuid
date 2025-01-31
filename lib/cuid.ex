defmodule Cuid do
  @moduledoc """
  Collision-resistant ids.

  Usage:

      # Start the generator
      {:ok, generator} = Cuid.start_link

      # Generate a new CUID
      Cuid.generate(generator)
  """

  @doc """
  Generates and returns a new CUID.
  """
  @spec generate(generator :: pid) :: String.t
  def generate(generator) do
    GenServer.call(generator, :generate)
  end

  use GenServer

  @doc """
  Starts a new generator.
  """
  def start_link(process_opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, process_opts)
  end

  ## Server callbacks

  def init(:ok) do
    {:ok, %{:fingerprint => get_fingerprint(), :count => 0}}
  end

  def handle_call(:generate, _, %{:fingerprint => fingerprint, :count => count} = state) do
    cuid = Enum.join([
      "c", timestamp(), format_counter(count), fingerprint, random_block(), random_block()
    ]) |> String.downcase

    {:reply, cuid, %{state | :count => count + 1}}
  end

  ## Helpers

  @block_size 4
  @base 36

  defp format_counter(num) do
    num
    |> Integer.to_string(@base)
    |> String.pad_leading(@block_size, <<48>>)
  end

  @discrete_values 1_679_616

  defp timestamp do
    {mega, uni, micro} = :os.timestamp
    rem((mega * 1_000_000 + uni) * 1_000_000 + micro, @discrete_values * @discrete_values)
    |> Integer.to_string(@base)
  end

  defp random_block do
    :rand.uniform(@discrete_values - 1)
    |> Integer.to_string(@base)
    |> String.pad_leading(@block_size, <<48>>)
  end

  @operator @base * @base

  defp get_fingerprint do
    pid = rem(String.to_integer(System.pid), @operator) * @operator

    hostname = to_charlist :net_adm.localhost
    hostid = rem(Enum.sum(hostname) + Enum.count(hostname) + @base, @operator)

    pid + hostid
    |> Integer.to_string(@base)
  end
end
