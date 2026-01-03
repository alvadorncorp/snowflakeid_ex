defmodule SnowflakeID.Clock do
  @moduledoc """
  Behaviour defining the time source used by the SnowflakeID generator.
  """

  @callback now_ms(state :: term) :: non_neg_integer()
end
