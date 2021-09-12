defmodule XLA.MixProject do
  use Mix.Project

  @version "0.1.1-dev"
  @github_repo "jonatanklosko/xla"

  def project do
    [
      app: :xla,
      version: @version,
      elixir: "~> 1.12",
      deps: deps(),
      compilers: [:xla | Mix.compilers()],
      aliases: aliases(),
      make_env: &make_env/0
    ]
  end

  def application do
    []
  end

  defp deps do
    [{:elixir_make, "~> 0.4", runtime: false}]
  end

  defp aliases do
    [
      "compile.xla": &compile/1,
      "build.release_tag": &build_release_tag/1,
      "build.release_archive_filename": &build_release_archive_filename/1,
      "build.archive_path": &build_archive_path/1
    ]
  end

  # Aliases used by the build scripts

  defp build_release_tag(_) do
    IO.puts(release_tag())
  end

  defp build_release_archive_filename(_) do
    IO.puts(archive_filename_with_target())
  end

  defp build_archive_path(_) do
    IO.puts(archive_path())
  end

  # Custom compiler, either fetches or builds the XLA extension

  defmodule InitError do
    defexception [:message]

    @impl true
    def blame(error, _stacktrace) do
      {error, []}
    end
  end

  defp compile(_) do
    if Mix.env() == :prod and not File.exists?(archive_path()) do
      if force_build?() do
        build()
      else
        download_precompiled()
      end
    end

    :ok
  end

  defp force_build?() do
    System.get_env("XLA_BUILD") == "true"
  end

  defp xla_target() do
    target = System.get_env("XLA_TARGET", "cpu")

    # TODO: if cuda is given we may try determining the version
    # and printing info that cudaxyz is assumed
    supported_xla_targets = ["cpu", "cuda", "rocm", "tpu", "cuda102", "cuda110", "cuda111"]

    unless target in supported_xla_targets do
      listing = supported_xla_targets |> Enum.map(&inspect/1) |> Enum.join(", ")

      raise InitError,
            "expected XLA_TARGET to be one of #{listing}, but got: #{inspect(target)}"
    end

    target
  end

  defp build() do
    # TODO: set XLA flags when cuda/tpu/rocm
    Mix.Task.run("compile.elixir_make")
  end

  # Additional environment variables passed to make
  defp make_env() do
    bazel_build_flags =
      case xla_target() do
        "cuda" <> _ -> "--config=cuda"
        "rocm" <> _ -> "--config=rocm --action_env=HIP_PLATFORM=hcc"
        "tpu" <> _ -> "--config=tpu"
        _ -> ""
      end

    %{"XLA_EXTENSION_INTERNAL_FLAGS" => bazel_build_flags}
  end

  defp download_precompiled() do
    archive_path = archive_path()
    expected_filename = archive_filename_with_target()

    unless network_tool() do
      exit_with_reason!(
        "Expected either curl or wget to be available in your system, but neither was found"
      )
    end

    Mix.shell().info(
      "No precompiled XLA archive found locally, trying to find a precompiled one online"
    )

    filenames =
      case list_release_files() do
        {:ok, filenames} ->
          filenames

        :error ->
          exit_with_reason!(
            "Couldn't find #{release_tag()} release under https://github.com/#{@github_repo}/releases"
          )
      end

    unless expected_filename in filenames do
      exit_with_reason!(
        "None of the precompiled archives matches your target\n" <>
          "  Expected: #{expected_filename}\n" <>
          "  Found:\n" <>
          (filenames |> Enum.map(&("    * " <> &1)) |> Enum.join("\n"))
      )
    end

    Mix.shell().info("Found a matching archive (#{expected_filename}), going to download it")

    if download_release_file(expected_filename, archive_path) == :error do
      exit_with_reason!("Failed to download the XLA archive")
    end

    Mix.shell().info("Successfully downloaded the XLA archive")
  end

  defp exit_with_reason!(message) do
    Mix.shell().error(message)

    Mix.shell().error(
      "\nYou can also proceed to regular compilation by setting an environment variable: XLA_BUILD=true"
    )

    raise InitError, "xla compilation aborted, see the output for more details"
  end

  defp release_tag() do
    "v" <> @version
  end

  defp archive_path() do
    Path.join([__DIR__, "priv", archive_filename()])
  end

  defp archive_filename() do
    "xla_extension.tar.gz"
  end

  defp archive_filename_with_target() do
    "xla_extension-#{target()}.tar.gz"
  end

  defp target() do
    {cpu, os} =
      :erlang.system_info(:system_architecture)
      |> List.to_string()
      |> String.split("-")
      |> case do
        ["arm" <> _, _vendor, "darwin" <> _ | _] -> {"aarch64", "darwin"}
        [cpu, _vendor, "darwin" <> _ | _] -> {cpu, "darwin"}
        [cpu, _vendor, os | _] -> {cpu, os}
        ["win32"] -> {"x86_64", "windows"}
      end

    "#{cpu}-#{os}-#{xla_target()}"
  end

  # Requests

  defp list_release_files() do
    url = "https://api.github.com/repos/#{@github_repo}/releases/tags/#{release_tag()}"

    with {:ok, body} <- get(url) do
      # We don't have a JSON library available here, so we do
      # a simple matching
      {:ok, Regex.scan(~r/"name":\s+"(.*\.tar\.gz)"/, body) |> Enum.map(&Enum.at(&1, 1))}
    end
  end

  defp download_release_file(filename, destination_path) do
    url = "https://github.com/#{@github_repo}/releases/download/#{release_tag()}/#{filename}"
    File.mkdir_p!(Path.dirname(destination_path))
    download(url, destination_path)
  end

  defp download(url, dest) do
    command =
      case network_tool() do
        :curl -> "curl --fail -L #{url} -o #{dest}"
        :wget -> "wget -O #{dest} #{url}"
      end

    case System.shell(command) do
      {_, 0} -> :ok
      _ -> :error
    end
  end

  defp get(url) do
    command =
      case network_tool() do
        :curl -> "curl --fail --silent -L #{url}"
        :wget -> "wget -q -O - #{url}"
      end

    case System.shell(command) do
      {body, 0} -> {:ok, body}
      _ -> :error
    end
  end

  defp network_tool() do
    cond do
      executable_exists?("curl") -> :curl
      executable_exists?("wget") -> :wget
      true -> nil
    end
  end

  defp executable_exists?(name), do: System.find_executable(name) != nil
end
