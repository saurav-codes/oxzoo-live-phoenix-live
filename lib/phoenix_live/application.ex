defmodule PhoenixLive.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    :persistent_term.put(
      {PhoenixLive.Zoo, :started},
      {System.monotonic_time(:second), DateTime.utc_now()}
    )

    PhoenixLive.Zoo.ProbeLock.init()

    children = [
      PhoenixLive.Repo,
      {Phoenix.PubSub, name: PhoenixLive.PubSub},
      PhoenixLiveWeb.Presence,
      PhoenixLiveWeb.Endpoint
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: PhoenixLive.Supervisor)
  end

  @impl true
  def config_change(changed, _new, removed) do
    PhoenixLiveWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
