defmodule PhoenixLiveWeb.Presence do
  use Phoenix.Presence, otp_app: :phoenix_live, pubsub_server: PhoenixLive.PubSub
end
