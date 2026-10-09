import Config

config :phoenix_live, PhoenixLive.Repo,
  url: System.get_env("DATABASE_URL", "ecto://postgres@127.0.0.1/phoenix_live_test"),
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

config :phoenix_live, PhoenixLiveWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: String.duplicate("test-only-not-a-secret-", 4),
  server: false

config :logger, level: :warning
config :phoenix, :plug_init_mode, :runtime
