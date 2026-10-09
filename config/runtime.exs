import Config

if System.get_env("PHX_SERVER") do
  config :phoenix_live, PhoenixLiveWeb.Endpoint, server: true
end

config :phoenix_live, PhoenixLiveWeb.Endpoint,
  http: [port: String.to_integer(System.get_env("PORT", "4000"))]

if config_env() == :prod do
  database_url = System.get_env("DATABASE_URL") || raise "DATABASE_URL is not set"
  secret_key_base = System.get_env("SECRET_KEY_BASE") || raise "SECRET_KEY_BASE is not set"

  if byte_size(secret_key_base) < 64 do
    raise "SECRET_KEY_BASE must be at least 64 bytes (mix phx.gen.secret)"
  end

  # ox provides PUBLIC_HOST and PUBLIC_URL; the host and the allowed
  # LiveView socket origin derive from them.
  host = System.get_env("PUBLIC_HOST") || raise "PUBLIC_HOST is not set"
  public_url = System.get_env("PUBLIC_URL", "https://" <> host)

  config :phoenix_live, PhoenixLive.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE", "5"))

  config :phoenix_live, PhoenixLiveWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [ip: {127, 0, 0, 1}],
    check_origin: [public_url],
    secret_key_base: secret_key_base
end
