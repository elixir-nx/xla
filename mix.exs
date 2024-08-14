defmodule XLA.MixProject do
  use Mix.Project

  @version "0.7.1"

  def project do
    [
      app: :xla,
      version: @version,
      description: "Precompiled XLA binaries",
      elixir: "~> 1.12",
      aliases: aliases(),
      deps: deps(),
      compilers: Mix.compilers() ++ if(build?(), do: [:elixir_make], else: []),
      make_env: &XLA.make_env/0,
      package: package(),
      docs: docs()
    ]
  end

  def application do
    [extra_applications: [:logger, :inets, :ssl, :public_key, :crypto]]
  end

  def aliases do
    [
      # When compiling the checksum task, code paths are pruned, so we
      # explicitly load hex back
      "hex.publish": ["xla.checksum", fn _ -> Mix.ensure_application!(:hex) end, "hex.publish"]
    ]
  end

  defp deps do
    [
      {:elixir_make, "~> 0.4", runtime: false},
      {:ex_doc, "~> 0.25", only: :dev, runtime: false}
    ]
  end

  def package do
    [
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => "https://github.com/elixir-nx/xla"
      },
      files: ~w(extension lib Makefile mix.exs README.md LICENSE CHANGELOG.md checksum.txt)
    ]
  end

  def docs do
    [
      main: "readme",
      source_url: "https://github.com/elixir-nx/xla",
      source_ref: "v#{@version}",
      extras: ["README.md"]
    ]
  end

  defp build?() do
    System.get_env("XLA_BUILD") in ~w(1 true)
  end
end
