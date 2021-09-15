defmodule XLA.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :xla,
      version: @version,
      description: "Precompiled Google's XLA binaries",
      elixir: "~> 1.12",
      deps: deps(),
      compilers: Mix.compilers() ++ if(build?(), do: [:elixir_make], else: []),
      make_env: &XLA.make_env/0,
      package: package()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [{:elixir_make, "~> 0.4", runtime: false}]
  end

  def package do
    [
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => "https://github.com/elixir-nx/xla"
      },
      files: ~w(extension Makefile mix.exs README.md LICENSE CHANGELOG.md)
    ]
  end

  defp build?() do
    System.get_env("XLA_BUILD") == "true"
  end
end
