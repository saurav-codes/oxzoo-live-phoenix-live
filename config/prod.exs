import Config

# Caddy terminates TLS; ox's own health check talks to 127.0.0.1 directly.
config :phoenix_live, PhoenixLiveWeb.Endpoint,
  force_ssl: [rewrite_on: [:x_forwarded_proto], exclude: [hosts: ["localhost", "127.0.0.1"]]]

config :logger, level: :info
