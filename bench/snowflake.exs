Application.ensure_all_started(:snowflakeid_ex)

# To test against snowflakex, uncomment the second line in the benchmark
# and also add snowflakex as a dependency to your mix.exs

Benchee.run(%{
  "snowflake" => fn -> SnowflakeID.next_id() end
  # "snowflakex" => fn -> Snowflakex.new() end
})
