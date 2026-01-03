defmodule SnowflakeID.UtilTest do
  use ExUnit.Case, async: false

  @epoch 1_000

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

  test "timestamp_of_id respects configured layout" do
    timestamp_bits = 51
    Application.put_env(:snowflake_id, :timestamp_bits, timestamp_bits)

    ts = 123
    machine_bits = SnowflakeID.Helper.machine_id_bits(timestamp_bits)

    <<id::unsigned-integer-size(64)>> = <<
      ts::unsigned-integer-size(timestamp_bits),
      1::unsigned-integer-size(machine_bits),
      5::unsigned-integer-size(12)
    >>

    assert SnowflakeID.Util.timestamp_of_id(id) == ts
  end

  test "first_snowflake_for_timestamp zeroes machine and sequence bits" do
    timestamp_bits = 41
    Application.put_env(:snowflake_id, :timestamp_bits, timestamp_bits)
    Application.put_env(:snowflake_id, :epoch, @epoch)

    target = @epoch + 500
    id = SnowflakeID.Util.first_snowflake_for_timestamp(target)
    machine_bits = SnowflakeID.Helper.machine_id_bits(timestamp_bits)

    <<ts::unsigned-integer-size(timestamp_bits), machine_id::unsigned-integer-size(machine_bits),
      seq::unsigned-integer-size(12)>> = <<id::unsigned-integer-size(64)>>

    assert ts == target - @epoch
    assert machine_id == 0
    assert seq == 0
  end

  test "real_timestamp_of_id adds epoch" do
    timestamp_bits = 41
    Application.put_env(:snowflake_id, :timestamp_bits, timestamp_bits)
    Application.put_env(:snowflake_id, :epoch, @epoch)

    ts = 200
    machine_bits = SnowflakeID.Helper.machine_id_bits(timestamp_bits)

    <<id::unsigned-integer-size(64)>> = <<
      ts::unsigned-integer-size(timestamp_bits),
      0::unsigned-integer-size(machine_bits),
      0::unsigned-integer-size(12)
    >>

    assert SnowflakeID.Util.real_timestamp_of_id(id) == ts + @epoch
  end
end
