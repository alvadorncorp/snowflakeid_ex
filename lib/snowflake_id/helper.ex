defmodule SnowflakeID.Helper do
  @moduledoc """
  Utility functions intended for SnowflakeID application.
  epoch() and machine_id() are useful for inspecting in production.
  """
  @id_bit_size 64
  @sequence_bits 12
  @min_timestamp_bits 41
  @max_timestamp_bits @id_bit_size - @sequence_bits - 1
  @default_config [
    nodes: [],
    epoch: 0,
    timestamp_bits: 42
  ]

  @doc """
  Grabs epoch from config value
  """
  @spec epoch() :: integer
  def epoch() do
    Application.get_env(:snowflakeid_ex, :epoch) || @default_config[:epoch]
  end

  @doc """
  Grabs timestamp bit size with a minimum of #{@min_timestamp_bits} bits
  """
  @spec timestamp_bits() :: pos_integer
  def timestamp_bits() do
    Application.get_env(:snowflakeid_ex, :timestamp_bits, @default_config[:timestamp_bits])
    |> clamp_timestamp_bits()
  end

  @doc """
  Returns how many machine id bits remain after reserving timestamp and sequence bits.
  """
  @spec machine_id_bits(pos_integer) :: pos_integer
  def machine_id_bits(timestamp_bits) do
    normalized_bits = clamp_timestamp_bits(timestamp_bits)
    remaining = @id_bit_size - @sequence_bits - normalized_bits
    max(remaining, 1)
  end

  @doc """
  Computes the maximum machine id value based on the configured timestamp bits.
  """
  @spec machine_id_max(pos_integer) :: non_neg_integer
  def machine_id_max(timestamp_bits) do
    bits = machine_id_bits(timestamp_bits)
    Integer.pow(2, bits) - 1
  end

  @doc false
  def clamp_timestamp_bits(bits) when is_integer(bits) do
    cond do
      bits < @min_timestamp_bits -> @min_timestamp_bits
      bits > @max_timestamp_bits -> @max_timestamp_bits
      true -> bits
    end
  end

  def clamp_timestamp_bits(_bits), do: clamp_timestamp_bits(@default_config[:timestamp_bits])

  @doc """
  Returns the machine id of the current node, constrained to the bits implied by
  the configured timestamp size. When no explicit machine id is configured, the
  helper inspects the hostname, fqdn, Node name, and IPs to find a match in the
  configured nodes list.
  """
  @spec machine_id(pos_integer | nil) :: integer
  def machine_id(timestamp_bits \\ timestamp_bits()) do
    normalized_bits = clamp_timestamp_bits(timestamp_bits)
    max_machine_id = machine_id_max(normalized_bits)

    configured_id = Application.get_env(:snowflakeid_ex, :machine_id)
    machine_id(configured_id, normalized_bits, max_machine_id)
  end

  defp machine_id(nil, _timestamp_bits, max_machine_id) do
    nodes = Application.get_env(:snowflakeid_ex, :nodes, @default_config[:nodes])
    host_addrs = [hostname(), fqdn(), Node.self()] ++ ip_addrs()

    with [matching_node] <-
           MapSet.intersection(MapSet.new(host_addrs), MapSet.new(nodes)) |> Enum.take(1),
         idx when is_integer(idx) <- Enum.find_index(nodes, fn node -> node == matching_node end),
         true <- idx <= max_machine_id do
      idx
    else
      _ -> max_machine_id
    end
  end

  defp machine_id(id, _timestamp_bits, max_machine_id)
       when is_integer(id) and id >= 0 and id <= max_machine_id,
       do: id

  defp machine_id(id, _timestamp_bits, max_machine_id) when is_integer(id), do: max_machine_id

  defp machine_id(_id, timestamp_bits, max_machine_id),
    do: machine_id(nil, timestamp_bits, max_machine_id)

  defp ip_addrs() do
    case :inet.getifaddrs() do
      {:ok, ifaddrs} ->
        ifaddrs
        |> Enum.flat_map(fn {_, kwlist} ->
          kwlist |> Enum.filter(fn {type, _} -> type == :addr end)
        end)
        |> Enum.filter(&(tuple_size(elem(&1, 1)) in [4, 6]))
        |> Enum.map(fn {_, addr} ->
          case addr do
            # ipv4
            {a, b, c, d} -> [a, b, c, d] |> Enum.join(".")
            # ipv6
            {a, b, c, d, e, f} -> [a, b, c, d, e, f] |> Enum.join(":")
          end
        end)

      _ ->
        []
    end
  end

  defp hostname() do
    {:ok, name} = :inet.gethostname()
    to_string(name)
  end

  defp fqdn() do
    case :inet.get_rc()[:domain] do
      nil -> nil
      domain -> hostname() <> "." <> to_string(domain)
    end
  end
end
