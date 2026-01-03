defmodule SnowflakeID do
  @moduledoc """
  Generates Snowflake IDs
  """
  use Application

  def start(_type, _args) do
    epoch = SnowflakeID.Helper.epoch()
    timestamp_bits = SnowflakeID.Helper.timestamp_bits()
    machine_id = SnowflakeID.Helper.machine_id(timestamp_bits)

    children = [
      %{
        id: SnowflakeID.Generator,
        start: {SnowflakeID.Generator, :start_link, [epoch, machine_id, timestamp_bits]}
      }
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  @doc """
  Generates a snowflake ID, each call is guaranteed to return a different ID
  that is sequantially larger than the previous ID.
  """
  @spec next_id() ::
          {:ok, integer}
          | {:error, :backwards_clock}
  def next_id() do
    GenServer.call(SnowflakeID.Generator, :next_id)
  end

  @doc """
  Returns the machine id of the current node.
  """
  @spec machine_id() :: {:ok, integer}
  def machine_id() do
    GenServer.call(SnowflakeID.Generator, :machine_id)
  end

  @doc """
  Returns the machine id of the current node.
  """
  @spec set_machine_id(integer) :: {:ok, integer}
  def set_machine_id(machine_id) do
    GenServer.call(SnowflakeID.Generator, {:set_machine_id, machine_id})
  end
end
