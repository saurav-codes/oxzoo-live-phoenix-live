defmodule PhoenixLive.Counter do
  @moduledoc "The shared click counter: one row in PG, changes broadcast over PubSub."
  import Ecto.Query
  alias PhoenixLive.Repo

  @topic "counter"

  def topic, do: @topic

  def get do
    Repo.one(from c in "counters", where: c.name == "clicks", select: c.value) || 0
  end

  def increment do
    {1, [value]} =
      from(c in "counters", where: c.name == "clicks", select: c.value)
      |> Repo.update_all(inc: [value: 1])

    Phoenix.PubSub.broadcast(PhoenixLive.PubSub, @topic, {:count, value})
    value
  end
end
