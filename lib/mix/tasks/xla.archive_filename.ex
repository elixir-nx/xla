defmodule Mix.Tasks.Xla.ArchiveFilename do
  @moduledoc """
  Returns XLA archive filename matching the current environment
  configuration.
  """

  use Mix.Task

  @impl true
  def run(_args) do
    Mix.shell().info(XLA.archive_filename_with_target())
  end
end
