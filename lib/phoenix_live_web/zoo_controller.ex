defmodule PhoenixLiveWeb.ZooController do
  use Phoenix.Controller, formats: [:json]
  alias PhoenixLive.Zoo

  def health(conn, _params), do: json(conn, Zoo.health())

  # Checks run concurrently with a 5 s cap each, so the probe stays well
  # under its 20 s budget.
  def probe(conn, _params) do
    case Zoo.ProbeLock.run(&Zoo.probe/0) do
      {:ok, body} -> json(conn, body)
      :busy -> conn |> put_status(429) |> json(%{error: "probe busy"})
    end
  end
end
