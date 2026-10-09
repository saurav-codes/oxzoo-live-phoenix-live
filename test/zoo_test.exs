defmodule PhoenixLive.ZooTest do
  use ExUnit.Case, async: false
  import Plug.Conn
  import Phoenix.ConnTest
  alias PhoenixLive.Zoo

  @endpoint PhoenixLiveWeb.Endpoint
  @panel "https://zoo-control.s1.zoo.sorv.dev"

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(PhoenixLive.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(PhoenixLive.Repo, {:shared, self()})
    System.put_env("ZOO_PANEL_ORIGIN", "#{@panel}, http://localhost:5173")
    on_exit(fn -> System.delete_env("ZOO_PANEL_ORIGIN") end)
    :ok
  end

  test "server label comes from PUBLIC_HOST" do
    assert Zoo.server("phoenix-live.s1.zoo.sorv.dev") == "s1"
    assert Zoo.server("example.com") == "local"
    assert Zoo.server(nil) == "local"
  end

  test "release is OX_RELEASE cut to 12 chars" do
    assert Zoo.release("3f9c2a1b4d5e6f708192") == "3f9c2a1b4d5e"
    assert Zoo.release(nil) == "unknown"
  end

  test "fingerprint matches the DESIGN.md vector" do
    assert Zoo.fp("zoo-test-key-0123456789abcdef") == "915a"
  end

  test "health answers without touching dependencies" do
    body = build_conn() |> get("/_zoo/health") |> json_response(200)
    assert body["name"] == "phoenix-live"
    assert body["env"] == "local"
    assert body["build"]["runtime"] =~ "elixir"
    assert is_integer(body["uptime_s"])
  end

  test "probe runs real round trips and reports vars by fingerprint" do
    System.put_env("SECRET_KEY_BASE", "zoo-test-key-0123456789abcdef")
    on_exit(fn -> System.delete_env("SECRET_KEY_BASE") end)
    body = build_conn() |> get("/_zoo/probe") |> json_response(200)
    assert body["ok"], inspect(body["checks"])
    assert Enum.map(body["checks"], & &1["id"]) == ["postgres", "pubsub", "release"]
    assert hd(body["checks"])["detail"] =~ "zoo_probe row round trip"
    assert hd(body["checks"])["env"] == ["DATABASE_URL"]

    assert %{"fp" => "915a", "role" => "secret"} =
             Enum.find(body["vars"], &(&1["name"] == "SECRET_KEY_BASE"))

    assert PhoenixLive.Repo.query!("SELECT count(*) FROM zoo_probe").rows == [[0]]
  end

  test "a missing secret is reported as missing" do
    body = build_conn() |> get("/_zoo/probe") |> json_response(200)
    assert %{"missing" => true} = Enum.find(body["vars"], &(&1["name"] == "SECRET_KEY_BASE"))
  end

  test "a second probe gets busy while one runs" do
    parent = self()

    holder =
      spawn(fn ->
        Zoo.ProbeLock.run(fn ->
          send(parent, :holding)
          receive do: (:release -> :ok)
        end)
      end)

    assert_receive :holding
    assert Zoo.ProbeLock.run(fn -> :ran end, 50) == :busy
    send(holder, :release)
    Process.sleep(50)
    assert Zoo.ProbeLock.run(fn -> :ran end, 50) == {:ok, :ran}
  end

  test "CORS echoes a listed origin with Vary, never *" do
    conn = build_conn() |> put_req_header("origin", @panel) |> get("/_zoo/health")
    assert get_resp_header(conn, "access-control-allow-origin") == [@panel]
    assert get_resp_header(conn, "vary") |> Enum.join(",") =~ "Origin"
    assert get_resp_header(conn, "access-control-allow-credentials") == []
  end

  test "CORS sends nothing for an unlisted origin" do
    conn = build_conn() |> put_req_header("origin", "https://evil.example") |> get("/_zoo/health")
    assert get_resp_header(conn, "access-control-allow-origin") == []
  end

  test "CORS preflight is 204 with methods, headers and max age" do
    conn =
      build_conn() |> put_req_header("origin", "http://localhost:5173") |> options("/_zoo/probe")

    assert conn.status == 204
    assert get_resp_header(conn, "access-control-allow-origin") == ["http://localhost:5173"]
    assert get_resp_header(conn, "access-control-allow-methods") == ["GET, POST, OPTIONS"]
    assert get_resp_header(conn, "access-control-allow-headers") == ["Content-Type"]
    assert get_resp_header(conn, "access-control-max-age") == ["600"]
  end
end
