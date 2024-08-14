defmodule XLA.Checksumer do
  @moduledoc false

  defstruct algorithm: :sha256

  defimpl Collectable do
    def into(checksumer) do
      state = :crypto.hash_init(checksumer.algorithm)

      collector = fn
        state, {:cont, chunk} when is_binary(chunk) ->
          :crypto.hash_update(state, chunk)

        state, :done ->
          hash = :crypto.hash_final(state)
          Base.encode16(hash, case: :lower)

        _state, :halt ->
          :ok
      end

      {state, collector}
    end
  end
end
