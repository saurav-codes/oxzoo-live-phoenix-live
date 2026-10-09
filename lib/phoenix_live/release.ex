defmodule PhoenixLive.Release do
  @moduledoc "Release tasks: ox runs `bin/phoenix_live eval 'PhoenixLive.Release.migrate()'` before the switch."
  @app :phoenix_live

  def migrate do
    Application.ensure_all_started(:ssl)
    Application.ensure_loaded(@app)

    for repo <- Application.fetch_env!(@app, :ecto_repos) do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end
end
