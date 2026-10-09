import Config

config :phoenix_live, ecto_repos: [PhoenixLive.Repo]

config :phoenix_live, PhoenixLiveWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: PhoenixLiveWeb.ErrorHTML, json: PhoenixLiveWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: PhoenixLive.PubSub,
  live_view: [signing_salt: "zoo-live"]

config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

import_config "#{config_env()}.exs"
