defmodule XLA do
  @moduledoc """
  API for accessing compiled XLA archives.
  """

  require Logger

  @github_repo "elixir-nx/xla"

  # The directory where we store all the archives
  @cache_dir Path.expand("../cache", __DIR__)
  @build_dir Path.join(@cache_dir, "build")
  @download_dir Path.join(@cache_dir, "download")
  @external_dir Path.join(@cache_dir, "external")

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

    supported_xla_targets = ["cpu", "cuda", "rocm", "tpu", "cuda102", "cuda110", "cuda111"]

    unless target in supported_xla_targets do
      listing = supported_xla_targets |> Enum.map(&inspect/1) |> Enum.join(", ")
      raise "expected XLA_TARGET to be one of #{listing}, but got: #{inspect(target)}"
    end

    target
  end

  @doc false
  def make_env() do
    bazel_build_flags =
      case xla_target() do
        "cuda" <> _ -> "--config=cuda"
        "rocm" <> _ -> "--config=rocm --action_env=HIP_PLATFORM=hcc"
        "tpu" <> _ -> "--config=tpu"
        _ -> ""
      end

    # Additional environment variables passed to make
    %{
      "BUILD_INTERNAL_FLAGS" => bazel_build_flags,
      "ROOT_DIR" => Path.expand("..", __DIR__),
      "BUILD_ARCHIVE" => archive_path_for_build(),
      "BUILD_ARCHIVE_DIR" => Path.dirname(archive_path_for_build())
    }
  end

  @doc false
  def release_tag() do
    version = Application.spec(:xla, :vsn)
    "v" <> to_string(version)
  end

  @doc false
  def archive_filename_with_target() do
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

  defp archive_path_for_build() do
    filename = archive_filename_with_target()
    Path.join(@build_dir, filename)
  end

  defp archive_path_for_external_download(url) do
    hash = url |> :erlang.md5() |> Base.encode32(case: :lower, padding: false)
    filename = "xla_extension-#{hash}.tar.gz"
    Path.join(@external_dir, filename)
  end

  defp archive_path_for_matching_download() do
    filename = archive_filename_with_target()
    Path.join(@download_dir, filename)
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
