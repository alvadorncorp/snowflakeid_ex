defmodule SnowflakeID.Clock.System do
  @moduledoc """
  Default clock implementation that returns the operating system time in
  milliseconds.
  """

  @behaviour SnowflakeID.Clock

  @impl true
  def now_ms(_state), do: System.os_time(:millisecond)
end
