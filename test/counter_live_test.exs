defmodule PhoenixLiveWeb.CounterLiveTest do
  use ExUnit.Case, async: false
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  @endpoint PhoenixLiveWeb.Endpoint

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(PhoenixLive.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(PhoenixLive.Repo, {:shared, self()})
    :ok
  end

  test "a click updates every open view and presence counts them" do
    start = PhoenixLive.Counter.get()
    {:ok, a, html} = live(build_conn(), "/")
    assert html =~ "phoenix-live"
    {:ok, b, _} = live(build_conn(), "/")

    a |> element("#inc") |> render_click()
    assert render(a) =~ ~s(id="count">#{start + 1}<)
    assert render(b) =~ ~s(id="count">#{start + 1}<)
    assert render(b) =~ "2 viewers online"
  end

  test "the page loads the LiveView client from the packages" do
    html = build_conn() |> get("/") |> html_response(200)
    assert html =~ "/vendor/lv/phoenix_live_view.min.js"

    assert build_conn() |> get("/vendor/lv/phoenix_live_view.min.js") |> response(200) =~
             "LiveView"

    assert build_conn() |> get("/vendor/phoenix/phoenix.min.js") |> response(200) =~ "Phoenix"
  end
end
