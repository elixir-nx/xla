defmodule Mix.Tasks.Xla.Info do
  @moduledoc """
  Returns relevant information about the XLA archive.
  """

  use Mix.Task

  @impl true
  def run(["archive_filename"]) do
    Mix.shell().info(XLA.archive_filename_with_target())
  end

  def run(["release_tag"]) do
    Mix.shell().info("v" <> XLA.version())
  end

  def run(["build_archive_dir"]) do
    Mix.shell().info(XLA.build_archive_dir())
  end

  def run(_args) do
    Mix.shell().error("""
    Usage:
    mix xla.info archive_filename
    mix xla.info release_tag\
    mix xla.info build_archive_dir\
    """)
  end
end
