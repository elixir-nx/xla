defmodule XLA do
  @moduledoc """
  API for accessing compiled XLA archives.
  """

  require Logger

  @version Mix.Project.config()[:version]
  @github_repo "elixir-nx/xla"

  @doc """
  Returns path to the precompiled XLA archive.

  Depending on the environment variables configuration,
  the path will point to either built or downloaded file.
  If not found locally, the file is downloaded when calling
  this function.
  """
  @spec archive_path!() :: Path.t()
  def archive_path!() do
    cond do
      build?() ->
        # The archive should have already been built by this point
        archive_path_for_build()

      url = xla_archive_url() ->
        path = archive_path_for_external_download(url)
        unless File.exists?(path), do: download_external!(url, path)
        path

      true ->
        path = archive_path_for_matching_download()
        unless File.exists?(path), do: download_matching!(path)
        path
    end
  end

  defp build?() do
    System.get_env("XLA_BUILD") in ~w(1 true)
  end

  defp xla_archive_url() do
    System.get_env("XLA_ARCHIVE_URL")
  end

  defp xla_target() do
    target = System.get_env("XLA_TARGET", "cpu")

    supported_xla_targets = ["cpu", "cuda", "rocm", "tpu", "cuda111", "cuda114", "cuda118"]

    unless target in supported_xla_targets do
      listing = supported_xla_targets |> Enum.map(&inspect/1) |> Enum.join(", ")
      raise "expected XLA_TARGET to be one of #{listing}, but got: #{inspect(target)}"
    end

    target
  end

  defp xla_cache_dir() do
    # The directory where we store all the archives
    if dir = System.get_env("XLA_CACHE_DIR") do
      Path.expand(dir)
    else
      :filename.basedir(:user_cache, "xla")
    end
  end

  @doc false
  def make_env() do
    bazel_build_flags_accelerator =
      case xla_target() do
        "cuda" <> _ -> ["--config=cuda"]
        "rocm" <> _ -> ["--config=rocm", "--action_env=HIP_PLATFORM=hcc"]
        "tpu" <> _ -> ["--config=tpu"]
        _ -> []
      end

    bazel_build_flags_cpu =
      case target_triplet() do
        {"aarch64", "darwin", _} -> ["--config=macos_arm64"]
        _ -> []
      end

    bazel_build_flags = Enum.join(bazel_build_flags_accelerator ++ bazel_build_flags_cpu, " ")

    # Additional environment variables passed to make
    %{
      "BUILD_INTERNAL_FLAGS" => bazel_build_flags,
      "ROOT_DIR" => Path.expand("..", __DIR__),
      "BUILD_ARCHIVE" => archive_path_for_build(),
      "BUILD_ARCHIVE_DIR" => build_archive_dir()
    }
  end

  @doc false
  def build_archive_dir() do
    Path.dirname(archive_path_for_build())
  end

  @doc false
  def release_tag() do
    "v" <> @version
  end

  @doc false
  def archive_filename_with_target() do
    "xla_extension-#{target()}.tar.gz"
  end

  defp target() do
    case target_triplet() do
      {arch, os, nil} -> "#{arch}-#{os}-#{xla_target()}"
      {arch, os, abi} -> "#{arch}-#{os}-#{abi}-#{xla_target()}"
    end
  end

  defp target_triplet() do
    if target = System.get_env("XLA_TARGET_PLATFORM") do
      case String.split(target, "-") do
        [arch, os, abi] ->
          {arch, os, abi}

        [arch, os] ->
          {arch, os, nil}

        other ->
          raise "expected XLA_TARGET_PLATFORM to be either ARCHITECTURE-OS-ABI or ARCHITECTURE-OS, got: #{other}"
      end
    else
      :erlang.system_info(:system_architecture)
      |> List.to_string()
      |> String.split("-")
      |> case do
        ["arm" <> _, _vendor, "darwin" <> _ | _] -> {"aarch64", "darwin", nil}
        [arch, _vendor, "darwin" <> _ | _] -> {arch, "darwin", nil}
        [arch, _vendor, os, abi] -> {arch, os, abi}
        ["win32"] -> {"x86_64", "windows", nil}
      end
    end
  end

  defp archive_path_for_build() do
    filename = archive_filename_with_target()
    cache_path(["build", filename])
  end

  defp archive_path_for_external_download(url) do
    hash = url |> :erlang.md5() |> Base.encode32(case: :lower, padding: false)
    filename = "xla_extension-#{hash}.tar.gz"
    cache_path(["external", filename])
  end

  defp archive_path_for_matching_download() do
    filename = archive_filename_with_target()
    cache_path(["download", filename])
  end

  defp cache_path(parts) do
    base_dir = xla_cache_dir()
    Path.join([base_dir, @version, "cache" | parts])
  end

  defp download_external!(url, archive_path) do
    assert_network_tool!()
    Logger.info("Downloading XLA archive from #{url}")
    download_archive!(url, archive_path)
  end

  defp download_matching!(archive_path) do
    assert_network_tool!()

    expected_filename = Path.basename(archive_path)

    filenames =
      case list_release_files() do
        {:ok, filenames} ->
          filenames

        :error ->
          raise "could not find #{release_tag()} release under https://github.com/#{@github_repo}/releases"
      end

    unless expected_filename in filenames do
      listing = filenames |> Enum.map(&["    * ", &1, "\n"]) |> IO.iodata_to_binary()

      raise "none of the precompiled archives matches your target\n" <>
              "  Expected:\n" <>
              "    * #{expected_filename}\n" <>
              "  Found:\n" <>
              listing <>
              "\nYou can compile XLA locally by setting an environment variable: XLA_BUILD=true"
    end

    Logger.info("Found a matching archive (#{expected_filename}), going to download it")
    url = release_file_url(expected_filename)
    download_archive!(url, archive_path)
  end

  defp download_archive!(url, archive_path) do
    File.mkdir_p!(Path.dirname(archive_path))

    if download(url, archive_path) == :error do
      raise "failed to download the XLA archive from #{url}"
    end

    Logger.info("Successfully downloaded the XLA archive")
  end

  defp assert_network_tool!() do
    unless network_tool() do
      raise "expected either curl or wget to be available in your system, but neither was found"
    end
  end

  defp list_release_files() do
    url = "https://api.github.com/repos/#{@github_repo}/releases/tags/#{release_tag()}"

    with {:ok, body} <- get(url) do
      # We don't have a JSON library available here, so we do
      # a simple matching
      {:ok, Regex.scan(~r/"name":\s+"(.*\.tar\.gz)"/, body) |> Enum.map(&Enum.at(&1, 1))}
    end
  end

  defp release_file_url(filename) do
    "https://github.com/#{@github_repo}/releases/download/#{release_tag()}/#{filename}"
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
