defmodule SnowflakeID.GeneratorTest do
  use ExUnit.Case, async: false

  @epoch 1_000

  test "encodes ids according to timestamp bit layout" do
    times = [@epoch, @epoch]

    with_generator(times, [timestamp_bits: 41, machine_id: 5, epoch: @epoch], fn name, ts_bits ->
      assert {:ok, id} = GenServer.call(name, :next_id)
      assert %{ts: 0, machine_id: 5, seq: 1} == decode(id, ts_bits)
    end)
  end

  test "sequence increments within same millisecond and resets afterwards" do
    times = [@epoch, @epoch, @epoch, @epoch + 1]

    with_generator(times, [epoch: @epoch], fn name, ts_bits ->
      {:ok, id1} = GenServer.call(name, :next_id)
      {:ok, id2} = GenServer.call(name, :next_id)
      {:ok, id3} = GenServer.call(name, :next_id)

      assert %{seq: 1} = decode(id1, ts_bits)
      assert %{seq: 2} = decode(id2, ts_bits)

      decoded = decode(id3, ts_bits)
      assert decoded.seq == 0
      assert decoded.ts == decode(id1, ts_bits).ts + 1
    end)
  end

  test "returns backwards_clock error when time goes backwards" do
    times = [@epoch, @epoch - 1]

    with_generator(times, [epoch: @epoch], fn name, _ts_bits ->
      assert {:error, :backwards_clock} = GenServer.call(name, :next_id)
    end)
  end

  test "normalizes machine id when set beyond maximum" do
    times = [@epoch, @epoch]

    with_generator(times, [timestamp_bits: 51, epoch: @epoch], fn name, _ts_bits ->
      assert {:ok, 1} = GenServer.call(name, {:set_machine_id, 99})
      assert {:ok, 1} = GenServer.call(name, :machine_id)
    end)
  end

  test "waits for new millisecond when sequence overflows" do
    base = @epoch
    times = [base] ++ List.duplicate(base, 4_096) ++ [base + 1]

    with_generator(times, [epoch: @epoch], fn name, ts_bits ->
      last_id =
        Enum.reduce(1..4_096, nil, fn _, _ ->
          {:ok, id} = GenServer.call(name, :next_id)
          id
        end)

      decoded = decode(last_id, ts_bits)
      assert decoded.seq == 0
      assert decoded.ts == 1
    end)
  end

  defp with_generator(times, opts, fun) do
    %{pid: pid, name: name, timestamp_bits: ts_bits, clock_state: clock_state} =
      start_generator_raw(Keyword.merge([clock_times: times], opts))

    try do
      fun.(name, ts_bits)
    after
      GenServer.stop(pid)
      Agent.stop(clock_state)
    end
  end

  defp start_generator_raw(opts) do
    times = Keyword.fetch!(opts, :clock_times)
    timestamp_bits = Keyword.get(opts, :timestamp_bits, 41)
    machine_id = Keyword.get(opts, :machine_id, 0)
    epoch = Keyword.get(opts, :epoch, @epoch)
    name = Keyword.get(opts, :name, unique_name())

    clock_state = SnowflakeID.TestClock.new(times)

    {:ok, pid} =
      SnowflakeID.Generator.start_link(epoch, machine_id, timestamp_bits,
        clock: {SnowflakeID.TestClock, clock_state},
        name: name
      )

    %{pid: pid, name: name, timestamp_bits: timestamp_bits, clock_state: clock_state}
  end

  defp decode(id, timestamp_bits) do
    machine_bits = SnowflakeID.Helper.machine_id_bits(timestamp_bits)

    <<ts::unsigned-integer-size(timestamp_bits), machine_id::unsigned-integer-size(machine_bits),
      seq::unsigned-integer-size(12)>> = <<id::unsigned-integer-size(64)>>

    %{ts: ts, machine_id: machine_id, seq: seq}
  end

  defp unique_name do
    String.to_atom("snowflakeid_generator_test_" <> Integer.to_string(System.unique_integer()))
  end
end
