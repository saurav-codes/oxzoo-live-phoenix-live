defmodule PhoenixLiveWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :phoenix_live

  @session_options [
    store: :cookie,
    key: "_phoenix_live_key",
    signing_salt: "zoo-sess",
    same_site: "Lax"
  ]

  socket "/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]]

  plug Plug.Static, at: "/", from: :phoenix_live, gzip: false, only: ~w(assets robots.txt)

  # The client JS ships inside the phoenix and phoenix_live_view packages,
  # so the build needs no Node, esbuild or npm.
  plug Plug.Static,
    at: "/vendor/phoenix",
    from: {:phoenix, "priv/static"},
    gzip: false,
    only: ~w(phoenix.min.js)

  plug Plug.Static,
    at: "/vendor/lv",
    from: {:phoenix_live_view, "priv/static"},
    gzip: false,
    only: ~w(phoenix_live_view.min.js)

  plug Plug.RequestId
  plug PhoenixLiveWeb.Cors

  plug Plug.Parsers,
    parsers: [:urlencoded, :json],
    pass: ["*/*"],
    length: 64_000,
    json_decoder: Jason

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug PhoenixLiveWeb.Router
end
