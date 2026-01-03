defmodule SnowflakeID.Generator do
  @moduledoc false
  use GenServer

  alias SnowflakeID.Helper

  @seq_overflow 4096
  @sequence_bits 12
  @id_bit_size 64

  def start_link(epoch, machine_id, timestamp_bits) do
    start_link(epoch, machine_id, timestamp_bits, [])
  end

  def start_link(epoch, machine_id, timestamp_bits, opts) do
    normalized_timestamp_bits = Helper.clamp_timestamp_bits(timestamp_bits)
    machine_bits = Helper.machine_id_bits(normalized_timestamp_bits)
    max_machine_id = Helper.machine_id_max(normalized_timestamp_bits)
    normalized_machine_id = normalize_machine_id(machine_id, max_machine_id)
    clock = opts |> Keyword.get(:clock, default_clock()) |> normalize_clock()
    name = Keyword.get(opts, :name, __MODULE__)

    state =
      {epoch, ts(epoch, clock), normalized_machine_id, 0, normalized_timestamp_bits, machine_bits,
       max_machine_id, clock}

    GenServer.start_link(__MODULE__, state, name: name)
  end

  def init(args) do
    {:ok, args}
  end

  def handle_call(
        :next_id,
        from,
        {epoch, prev_ts, machine_id, seq, timestamp_bits, machine_bits, max_machine_id, clock} =
          state
      ) do
    case next_ts_and_seq(epoch, prev_ts, seq, clock) do
      {:error, :seq_overflow} ->
        :timer.sleep(1)
        handle_call(:next_id, from, state)

      {:error, :backwards_clock} ->
        {:reply, {:error, :backwards_clock}, state}

      {:ok, new_ts, new_seq} ->
        new_state =
          {epoch, new_ts, machine_id, new_seq, timestamp_bits, machine_bits, max_machine_id,
           clock}

        {:reply, {:ok, create_id(new_ts, machine_id, new_seq, timestamp_bits, machine_bits)},
         new_state}
    end
  end

  def handle_call(
        :machine_id,
        _from,
        {_epoch, _prev_ts, machine_id, _seq, _timestamp_bits, _machine_bits, _max_machine_id,
         _clock} = state
      ) do
    {:reply, {:ok, machine_id}, state}
  end

  def handle_call(
        {:set_machine_id, machine_id},
        _from,
        {epoch, prev_ts, _old_machine_id, seq, timestamp_bits, machine_bits, max_machine_id,
         clock}
      ) do
    normalized_machine_id = normalize_machine_id(machine_id, max_machine_id)

    new_state =
      {epoch, prev_ts, normalized_machine_id, seq, timestamp_bits, machine_bits, max_machine_id,
       clock}

    {:reply, {:ok, normalized_machine_id}, new_state}
  end

  defp next_ts_and_seq(epoch, prev_ts, seq, clock) do
    case ts(epoch, clock) do
      ^prev_ts ->
        case seq + 1 do
          @seq_overflow -> {:error, :seq_overflow}
          next_seq -> {:ok, prev_ts, next_seq}
        end

      new_ts ->
        cond do
          new_ts < prev_ts -> {:error, :backwards_clock}
          true -> {:ok, new_ts, 0}
        end
    end
  end

  defp create_id(ts, machine_id, seq, timestamp_bits, machine_bits) do
    <<new_id::unsigned-integer-size(@id_bit_size)>> = <<
      ts::unsigned-integer-size(timestamp_bits),
      machine_id::unsigned-integer-size(machine_bits),
      seq::unsigned-integer-size(@sequence_bits)
    >>

    new_id
  end

  defp normalize_machine_id(id, max_machine_id)
       when is_integer(id) and id >= 0 and id <= max_machine_id,
       do: id

  defp normalize_machine_id(_id, max_machine_id), do: max_machine_id

  defp normalize_clock({mod, state}) when is_atom(mod), do: {mod, state}
  defp normalize_clock(mod) when is_atom(mod), do: {mod, nil}

  defp ts(epoch, {clock_mod, clock_state}) do
    clock_mod.now_ms(clock_state) - epoch
  end

  defp default_clock, do: {SnowflakeID.Clock.System, nil}
end
