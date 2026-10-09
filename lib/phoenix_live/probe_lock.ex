defmodule PhoenixLive.Zoo.ProbeLock do
  @moduledoc "One probe at a time per process; a second caller waits up to 5 s."
  @table :zoo_probe_lock
  @step 25

  def init, do: :ets.new(@table, [:named_table, :public, :set])

  @doc "Runs fun under the lock, or returns :busy after wait_ms."
  def run(fun, wait_ms \\ 5_000) do
    if acquire(wait_ms) do
      try do
        {:ok, fun.()}
      after
        :ets.delete(@table, :busy)
      end
    else
      :busy
    end
  end

  defp acquire(left) do
    cond do
      :ets.insert_new(@table, {:busy, self()}) -> true
      left <= 0 -> false
      true -> Process.sleep(@step) && acquire(left - @step)
    end
  end
end
