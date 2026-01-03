defmodule SnowflakeID.HelperTest do
  use ExUnit.Case, async: false

  setup do
    original_env = Application.get_all_env(:snowflake_id)

    on_exit(fn ->
      Application.get_all_env(:snowflake_id)
      |> Enum.each(fn {key, _} -> Application.delete_env(:snowflake_id, key) end)

      Enum.each(original_env, fn {key, value} ->
        Application.put_env(:snowflake_id, key, value)
      end)
    end)

    :ok
  end

  describe "timestamp_bits/0" do
    test "enforces minimum of 41 bits" do
      Application.put_env(:snowflake_id, :timestamp_bits, 10)
      assert SnowflakeID.Helper.timestamp_bits() == 41
    end

    test "enforces maximum derived from layout" do
      Application.put_env(:snowflake_id, :timestamp_bits, 100)
      assert SnowflakeID.Helper.timestamp_bits() == 51
    end
  end

  test "machine_id_bits subtracts timestamp and sequence bits" do
    assert SnowflakeID.Helper.machine_id_bits(41) == 11
    assert SnowflakeID.Helper.machine_id_bits(51) == 1
  end

  test "machine_id_max returns inclusive limit" do
    assert SnowflakeID.Helper.machine_id_max(41) == Integer.pow(2, 11) - 1
    assert SnowflakeID.Helper.machine_id_max(51) == 1
  end

  describe "machine_id/1" do
    test "clamps configured machine id to maximum" do
      Application.put_env(:snowflake_id, :timestamp_bits, 51)
      Application.put_env(:snowflake_id, :machine_id, 99)
      assert SnowflakeID.Helper.machine_id(51) == 1
    end

    test "derives from nodes when within range" do
      Application.put_env(:snowflake_id, :nodes, [Node.self()])
      assert SnowflakeID.Helper.machine_id(41) == 0
    end

    test "falls back to max when derived index exceeds available bits" do
      Application.put_env(:snowflake_id, :nodes, [:one, :two, Node.self()])
      assert SnowflakeID.Helper.machine_id(51) == 1
    end
  end
end
