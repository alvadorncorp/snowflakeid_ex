defmodule SnowflakeID.TestClock do
  @moduledoc false

  @behaviour SnowflakeID.Clock

  def new(sequence) when is_list(sequence) do
    {:ok, pid} = Agent.start_link(fn -> sequence end)
    pid
  end

  @impl true
  def now_ms(agent) do
    Agent.get_and_update(agent, fn
      [next | rest] -> {next, rest}
      [] -> raise "test clock sequence exhausted"
    end)
  end
end
