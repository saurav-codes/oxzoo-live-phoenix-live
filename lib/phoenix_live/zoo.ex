defmodule PhoenixLive.Zoo do
  @moduledoc "The oxzoo-live contract: health and probe bodies (DESIGN.md)."

  @name "phoenix-live"
  @stack "Phoenix 1.8 LiveView + Ecto"
  @built_at DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()
  @check_timeout 5_000

  def name, do: @name

  def identity do
    %{
      name: @name,
      stack: @stack,
      server: server(System.get_env("PUBLIC_HOST")),
      release: release(System.get_env("OX_RELEASE")),
      env: System.get_env("OX_ENV") || "local"
    }
  end

  def health do
    {mono, started_at} = :persistent_term.get({__MODULE__, :started})

    Map.merge(identity(), %{
      uptime_s: System.monotonic_time(:second) - mono,
      started_at: DateTime.to_iso8601(DateTime.truncate(started_at, :second)),
      build: %{built_at: @built_at, runtime: runtime()}
    })
  end

  @doc "The `sN` label of PUBLIC_HOST, else local."
  def server(nil), do: "local"

  def server(host) do
    host |> String.split(".") |> Enum.find("local", &Regex.match?(~r/^s[0-9]+$/, &1))
  end

  def release(nil), do: "unknown"
  def release(""), do: "unknown"
  def release(rel), do: String.slice(rel, 0, 12)

  @doc "The last 4 hex characters of sha256(value)."
  def fp(value),
    do: :crypto.hash(:sha256, value) |> Base.encode16(case: :lower) |> String.slice(-4, 4)

  def runtime, do: "elixir #{System.version()} otp #{System.otp_release()}"

  @doc "Runs every check concurrently, each capped at 5 s."
  def probe do
    t0 = System.monotonic_time(:millisecond)

    checks =
      [postgres: &postgres/0, pubsub: &pubsub/0, release: &release_info/0]
      |> Task.async_stream(&timed/1, timeout: @check_timeout + 500, on_timeout: :kill_task)
      |> Enum.zip([:postgres, :pubsub, :release])
      |> Enum.map(fn
        {{:ok, check}, _} -> check
        {{:exit, _}, id} -> fail(meta(id), "timeout after #{@check_timeout} ms", @check_timeout)
      end)

    Map.merge(identity(), %{
      ok: Enum.all?(checks, & &1.ok),
      ms: System.monotonic_time(:millisecond) - t0,
      at: DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601(),
      checks: checks,
      vars: vars()
    })
  end

  defp vars do
    [
      secret_var("SECRET_KEY_BASE", "secret"),
      case System.get_env("ZOO_PANEL_ORIGIN") do
        nil -> %{name: "ZOO_PANEL_ORIGIN", missing: true, role: "plain"}
        v -> %{name: "ZOO_PANEL_ORIGIN", value: v, role: "plain"}
      end
    ]
  end

  defp secret_var(name, role) do
    case System.get_env(name) do
      nil -> %{name: name, missing: true, role: role}
      v -> %{name: name, fp: fp(v), role: role}
    end
  end

  defp meta(:postgres),
    do: %{id: "postgres", label: "Postgres write, read, delete via Ecto", env: ["DATABASE_URL"]}

  defp meta(:pubsub), do: %{id: "pubsub", label: "Phoenix.PubSub broadcast round trip", env: []}

  defp meta(:release),
    do: %{id: "release", label: "Release and runtime info", env: ["OX_RELEASE"]}

  defp hops, do: ["#{@name}@#{server(System.get_env("PUBLIC_HOST"))}"]

  defp timed({id, fun}) do
    t = System.monotonic_time(:millisecond)
    result = safe(fun)
    ms = System.monotonic_time(:millisecond) - t

    case result do
      {:ok, detail} -> Map.merge(meta(id), %{ok: true, ms: ms, detail: detail, hops: hops()})
      {:error, error} -> fail(meta(id), error, ms)
    end
  end

  defp safe(fun) do
    fun.()
  rescue
    e -> {:error, Exception.message(e) |> String.slice(0, 200)}
  end

  defp fail(meta, error, ms),
    do: Map.merge(meta, %{ok: false, ms: ms, error: error, hops: hops()})

  @doc false
  def postgres do
    alias PhoenixLive.Repo
    token = Base.encode16(:crypto.strong_rand_bytes(8), case: :lower)
    opts = [timeout: @check_timeout]

    with {:ok, %{rows: [[id]]}} <-
           Repo.query("INSERT INTO zoo_probe (token) VALUES ($1) RETURNING id", [token], opts),
         {:ok, %{rows: [[^token]]}} <-
           Repo.query("SELECT token FROM zoo_probe WHERE id = $1", [id], opts),
         {:ok, %{num_rows: 1}} <- Repo.query("DELETE FROM zoo_probe WHERE id = $1", [id], opts),
         {:ok, %{rows: [[version]]}} <- Repo.query("SHOW server_version", [], opts) do
      {:ok, "zoo_probe row round trip, server #{version}"}
    else
      {:error, e} -> {:error, Exception.message(e) |> String.slice(0, 200)}
      other -> {:error, "unexpected result: #{inspect(other) |> String.slice(0, 120)}"}
    end
  end

  @doc false
  def pubsub do
    topic = "zoo_probe:" <> Base.encode16(:crypto.strong_rand_bytes(6), case: :lower)
    nonce = make_ref()
    :ok = Phoenix.PubSub.subscribe(PhoenixLive.PubSub, topic)
    :ok = Phoenix.PubSub.broadcast(PhoenixLive.PubSub, topic, {:zoo_probe, nonce})

    result =
      receive do
        {:zoo_probe, ^nonce} -> {:ok, "broadcast received on #{topic}"}
      after
        @check_timeout -> {:error, "timeout after #{@check_timeout} ms"}
      end

    Phoenix.PubSub.unsubscribe(PhoenixLive.PubSub, topic)
    result
  end

  @doc false
  def release_info do
    vsn = Application.spec(:phoenix_live, :vsn) |> to_string()

    detail =
      case System.get_env("RELEASE_NAME") do
        nil -> "mix (not a release), app #{vsn}, #{runtime()}"
        rel -> "release #{rel} #{System.get_env("RELEASE_VSN")}, app #{vsn}, #{runtime()}"
      end

    {:ok, detail}
  end
end
