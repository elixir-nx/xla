defmodule Mix.Tasks.Xla.ReleaseTag do
  @moduledoc """
  Returns XLA release tag.
  """

  use Mix.Task

  @impl true
  def run(_args) do
    Mix.shell().info(XLA.release_tag())
  end
end
