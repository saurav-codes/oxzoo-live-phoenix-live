defmodule PhoenixLiveWeb.Router do
  use Phoenix.Router, helpers: false
  import Plug.Conn
  import Phoenix.Controller
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {PhoenixLiveWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :zoo do
    plug :accepts, ["json"]
  end

  scope "/_zoo", PhoenixLiveWeb do
    pipe_through :zoo
    get "/health", ZooController, :health
    get "/probe", ZooController, :probe
  end

  scope "/", PhoenixLiveWeb do
    pipe_through :browser
    live "/", CounterLive
  end
end
