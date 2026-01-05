defmodule SnowflakeID.Mixfile do
  use Mix.Project

  @version "1.0.0"
  @url "https://github.com/alvadorncorp/snowflakeid_ex"
  @maintainers ["Igor Sant'Ana"]
  @elixir_requirement "~> 1.15"

  def project do
    [
      name: "SnowflakeID",
      app: :snowflake_id,
      version: @version,
      source_url: @url,
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      maintainers: @maintainers,
      description: "Elixir SnowflakeID Generator",
      elixir: @elixir_requirement,
      package: package(),
      homepage_url: @url,
      docs: docs(),
      deps: deps()
    ]
  end

  def application do
    [applications: [], mod: {SnowflakeID, []}]
  end

  defp deps do
    [
      {:benchee, "~> 1.5", only: :dev},
      {:ex_doc, "~> 0.39", only: :dev}
    ]
  end

  def docs do
    [
      extras: ["README.md", "CHANGELOG.md"],
      source_ref: "v#{@version}"
    ]
  end

  defp package do
    [
      maintainers: @maintainers,
      licenses: ["MIT"],
      links: %{github: @url},
      files: ~w(lib) ++ ~w(CHANGELOG.md LICENSE mix.exs README.md)
    ]
  end
end
