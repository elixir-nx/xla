defmodule XLA do
  @moduledoc """
  API for accessing precompiled XLA archives.
  """

  require Logger

  @version Mix.Project.config()[:version]

  @base_url "https://github.com/elixir-nx/xla/releases/download/v#{@version}"

  @precompiled_targets [
    "x86_64-darwin-cpu",
    "aarch64-darwin-cpu",
    "x86_64-linux-gnu-cpu",
    "aarch64-linux-gnu-cpu",
    "x86_64-linux-gnu-cuda12",
    "aarch64-linux-gnu-cuda12",
    "x86_64-linux-gnu-tpu"
  ]

  @supported_xla_targets ["cpu", "cuda", "rocm", "tpu", "cuda12"]

  @doc """
  Returns path to the precompiled XLA archive.

  Depending on the environment variables configuration,
  the path will point to either built or downloaded file.
  If not found locally, the file is downloaded when calling
  this function.
  """
  @spec archive_path!() :: Path.t()
  def archive_path!() do
    XLA.Utils.start_inets_profile()

    cond do
      build?() ->
        # The archive should have already been built by this point
        archive_path_for_build()

      url = xla_archive_url() ->
        path = archive_path_for_external_download(url)
        unless File.exists?(path), do: download_external!(url, path)
        path

      true ->
        path = archive_path_for_precompiled_download()
        unless File.exists?(path), do: download_precompiled!(path)
        path
    end
  after
    XLA.Utils.stop_inets_profile()
  end

  defp build?() do
    System.get_env("XLA_BUILD") in ~w(1 true)
  end

  defp xla_archive_url() do
    System.get_env("XLA_ARCHIVE_URL")
  end

  defp xla_target() do
    target = System.get_env("XLA_TARGET") || infer_xla_target() || "cpu"

    supported_xla_targets = @supported_xla_targets

    unless target in supported_xla_targets do
      listing = supported_xla_targets |> Enum.map(&inspect/1) |> Enum.join(", ")
      raise "expected XLA_TARGET to be one of #{listing}, but got: #{inspect(target)}"
    end

    target
  end

  defp infer_xla_target() do
    with nvcc when nvcc != nil <- System.find_executable("nvcc"),
         {output, 0} <- System.cmd(nvcc, ["--version"]) do
      if output =~ "release 12.", do: "cuda12"
    else
      _ -> nil
    end
  end

  defp xla_cache_dir() do
    # The directory where we store all the archives
    if dir = System.get_env("XLA_CACHE_DIR") do
      Path.expand(dir)
    else
      :filename.basedir(:user_cache, "xla")
    end
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
        [arch, _vendor, os] -> {arch, os, nil}
        ["win32"] -> {"x86_64", "windows", nil}
      end
    end
  end

  defp archive_path_for_build() do
    filename = archive_filename(target())
    cache_path(["build", filename])
  end

  defp archive_path_for_external_download(url) do
    hash = url |> :erlang.md5() |> Base.encode32(case: :lower, padding: false)
    filename = "xla_extension-#{hash}.tar.gz"
    cache_path(["external", filename])
  end

  defp archive_path_for_precompiled_download() do
    filename = archive_filename(target())
    cache_path(["download", filename])
  end

  defp archive_filename(target) do
    "xla_extension-#{@version}-#{target}.tar.gz"
  end

  defp cache_path(parts) do
    base_dir = xla_cache_dir()
    Path.join([base_dir, @version | parts])
  end

  defp download_external!(url, archive_path) do
    Logger.info("Downloading XLA archive from #{url}")

    case download_archive(url, archive_path) do
      :ok ->
        Logger.info("Successfully downloaded the XLA archive")

      {:error, message} ->
        File.rm(archive_path)
        raise message
    end
  end

  defp download_precompiled!(archive_path) do
    expected_filename = Path.basename(archive_path)

    target = target()
    precompiled_targets = precompiled_targets()

    if target not in precompiled_targets do
      listing = Enum.map_join(precompiled_targets, "\n", &("  * " <> &1))

      raise """
      no precompiled XLA archive available for this target: #{target}.

      The available targets are:

      #{listing}

      You can compile XLA locally by setting an environment variable: XLA_BUILD=true\
      """
    end

    Logger.info("Downloading a precompiled XLA archive for target #{target}")

    url = release_file_url(expected_filename)

    with :ok <- download_archive(url, archive_path),
         :ok <- verify_integrity(archive_path) do
      Logger.info("Successfully downloaded the XLA archive")
    else
      {:error, message} ->
        File.rm(archive_path)
        raise message
    end
  end

  defp release_file_url(filename) do
    @base_url <> "/" <> filename
  end

  defp download_archive(url, archive_path) do
    File.mkdir_p!(Path.dirname(archive_path))

    file = File.stream!(archive_path)

    case XLA.Utils.download(url, file) do
      {:ok, _file} ->
        :ok

      {:error, message} ->
        {:error, "failed to download the XLA archive from #{url}, reason: #{message}"}
    end
  end

  defp verify_integrity(path) do
    filename = Path.basename(path)
    checksum = compute_file_checksum!(path)

    case read_checksums!() do
      %{^filename => ^checksum} ->
        :ok

      %{^filename => _} ->
        {:error, "the integrity check failed for file #{filename}, the checksum does not match"}

      %{} ->
        {:error, "no entry for file #{filename} in the checksum file"}
    end
  end

  @doc false
  def write_checksums!(%{} = checksums) do
    content =
      checksums
      |> Enum.sort()
      |> Enum.map_join("", fn {filename, checksum} ->
        checksum <> "  " <> filename <> "\n"
      end)

    File.write!(checksum_path(), content)
  end

  defp read_checksums!() do
    content = File.read!(checksum_path())

    for line <- String.split(content, "\n", trim: true), into: %{} do
      [checksum, filename] = String.split(line, "  ")
      {filename, checksum}
    end
  end

  defp compute_file_checksum!(path) do
    path
    |> File.stream!([], 64_000)
    |> Enum.into(%XLA.Checksumer{})
  end

  defp checksum_path() do
    # Note that this path points to the project source, which normally
    # may not be available at runtime (in releases). However, we expect
    # XLA to be called only during compilation, in which case this path
    # is still available
    Path.expand("../checksum.txt", __DIR__)
  end

  defp precompiled_targets(), do: @precompiled_targets

  # Used by tasks

  @doc false
  def build_archive_dir() do
    Path.dirname(archive_path_for_build())
  end

  @doc false
  def version(), do: @version

  @doc false
  def archive_filename_with_target() do
    archive_filename(target())
  end

  @doc false
  def precompiled_files() do
    for target <- @precompiled_targets do
      filename = archive_filename(target)
      url = release_file_url(filename)
      {filename, url}
    end
  end

  # Configuration for elixir_make

  @doc false
  def make_env() do
    bazel_build_flags_accelerator =
      case xla_target() do
        "cuda" <> _ ->
          [
            # See https://github.com/google/jax/blob/66a92c41f6bac74960159645158e8d932ca56613/.bazelrc#L68
            ~s/--config=cuda --action_env=TF_CUDA_COMPUTE_CAPABILITIES="sm_50,sm_60,sm_70,sm_80,compute_90"/
          ]

        "rocm" <> _ ->
          [
            "--config=rocm",
            "--action_env=HIP_PLATFORM=hcc",
            # See https://github.com/google/jax/blob/66a92c41f6bac74960159645158e8d932ca56613/.bazelrc#L128
            ~s/--action_env=TF_ROCM_AMDGPU_TARGETS="gfx900,gfx906,gfx908,gfx90a,gfx1030,gfx1100"/
          ]

        "tpu" <> _ ->
          ["--config=tpu"]

        _ ->
          []
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
end
