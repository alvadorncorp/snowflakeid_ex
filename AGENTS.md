# AGENT PLAYBOOK
1. Repo uses Elixir/Mix; stay in project root unless noted.
2. No Cursor (.cursor) or Copilot (.github/copilot-instructions.md) rules exist—this file is authoritative.
3. Install deps with `mix deps.get`; build via `mix compile`.
4. Format with `mix format`; enforce using `mix format --check-formatted` in CI-style runs.
5. Run the full suite using `mix test` before shipping changes.
6. For single tests use `mix test test/<file>_test.exs:LINE` (adjust path/line).
7. Benchmarks live in `bench/snowflake.exs`; execute `mix run bench/snowflake.exs` only when performance-sensitive.
8. Document modules and public functions with @moduledoc/@doc plus matching @spec annotations.
9. Modules stay CamelCase; functions, variables, and private helpers must remain snake_case.
10. Keep module attributes for configuration-like constants (e.g., @seq_overflow) and uppercase them descriptively.
11. Order alias/import/use blocks alphabetically; prefer alias for reused modules, otherwise fully qualify calls.
12. Limit imports to macro-heavy modules; rely on alias/fully-qualified names elsewhere.
13. Pattern-match or guard in function heads to avoid nested conditionals; keep branches concise.
14. Favor immutable data updates with descriptive tuples/structs; avoid in-place ETS-style mutation unless documented.
15. Handle errors with tagged tuples (`{:ok, value}`, `{:error, reason}`); only raise when the process must crash.
16. GenServer callbacks must return canonical tuple shapes; avoid side-effects outside callback bodies.
17. Use `SnowflakeID.Helper` for epoch/machine-id lookups; do not duplicate config parsing.
18. Respect configuration from `config/config.exs`; never hardcode node lists or epochs inside libs.
19. When editing docs/changelog keep Markdown formatting consistent (ATX headings, fenced code blocks).
