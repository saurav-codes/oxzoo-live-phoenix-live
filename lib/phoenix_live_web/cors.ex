defmodule PhoenixLiveWeb.Cors do
  @moduledoc "CORS for /_zoo/* from the ZOO_PANEL_ORIGIN allowlist; never `*`, never credentials."
  import Plug.Conn

  def init(opts), do: opts

  def call(%Plug.Conn{path_info: ["_zoo" | _]} = conn, _opts) do
    origin = conn |> get_req_header("origin") |> List.first()
    conn = if allowed?(origin), do: allow(conn, origin), else: conn

    if conn.method == "OPTIONS" do
      conn |> send_resp(204, "") |> halt()
    else
      conn
    end
  end

  def call(conn, _opts), do: conn

  def allowed?(nil), do: false

  def allowed?(origin) do
    (System.get_env("ZOO_PANEL_ORIGIN") || "")
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.member?(origin)
  end

  defp allow(conn, origin) do
    conn =
      conn
      |> put_resp_header("access-control-allow-origin", origin)
      |> put_resp_header("vary", "Origin")

    if conn.method == "OPTIONS" do
      conn
      |> put_resp_header("access-control-allow-methods", "GET, POST, OPTIONS")
      |> put_resp_header("access-control-allow-headers", "Content-Type")
      |> put_resp_header("access-control-max-age", "600")
    else
      conn
    end
  end
end
