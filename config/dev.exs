import Config

# Local only: a Postgres on 127.0.0.1 with trust auth, no password.
config :phoenix_live, PhoenixLive.Repo,
  url: System.get_env("DATABASE_URL", "ecto://postgres@127.0.0.1/phoenix_live_dev")

config :phoenix_live, PhoenixLiveWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}],
  check_origin: false,
  debug_errors: true,
  secret_key_base: String.duplicate("dev-only-not-a-secret-", 4)
