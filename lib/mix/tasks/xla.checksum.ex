defmodule Mix.Tasks.Xla.Checksum do
  @moduledoc """
  Generates a checksum file for all precompiled artifacts.
  """

  use Mix.Task

  @impl true
  def run(_args) do
    XLA.Utils.start_inets_profile()

    Mix.shell().info("Downloading and computing checksums...")

    checksums =
      XLA.precompiled_files()
      |> Task.async_stream(
        fn {filename, url} ->
          {filename, download_checksum!(url)}
        end,
        timeout: :infinity,
        ordered: false
      )
      |> Map.new(fn {:ok, {filename, checksum}} -> {filename, checksum} end)

    XLA.write_checksums!(checksums)

    Mix.shell().info("Checksums written")
  after
    XLA.Utils.stop_inets_profile()
  end

  defp download_checksum!(url) do
    case with_retry(fn -> XLA.Utils.download(url, %XLA.Checksumer{}) end, 3) do
      {:ok, checksum} ->
        checksum

      {:error, message} ->
        Mix.raise("failed to download archive from #{url}, reason: #{message}")
    end
  end

  defp with_retry(fun, retries) when retries > 0 do
    first_try = fun.()

    Enum.reduce_while(1..retries//1, first_try, fn n, result ->
      case result do
        {:ok, _} ->
          {:halt, result}

        {:error, message} ->
          Mix.shell().info("Retrying request, attempt #{n} failed with reason: #{message}")

          wait_in_ms = :rand.uniform(n * 2_000)
          Process.sleep(wait_in_ms)

          {:cont, fun.()}
      end
    end)
  end
end
