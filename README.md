# phoenix-live

> **Role in the zoo:** project `phoenix-live` of [oxzoo-live](https://github.com/saurav-codes/oxzoo-live-control/blob/main/zoo/README.md#projects), deployed with ox on server s1 at https://phoenix-live.s1.zoo.sorv.dev. The contract it follows is [DESIGN.md](https://github.com/saurav-codes/oxzoo-live-control/blob/main/zoo/DESIGN.md).

Phoenix 1.8 LiveView + Ecto on Postgres, on s1 (`phoenix-live.s1.zoo.sorv.dev`), proof level P2.

The page at `/` is a shared click counter: the count lives in a Postgres row, every click is
broadcast over `Phoenix.PubSub` to every open tab, and `Phoenix.Presence` shows how many tabs
are watching. It needs no Node at all: `phoenix.min.js` and `phoenix_live_view.min.js` are
served straight from the `phoenix` and `phoenix_live_view` packages' `priv/static`
(`/vendor/phoenix/...`, `/vendor/lv/...`), and a seven-line `priv/static/assets/app.js` connects
the LiveSocket. No esbuild, no tailwind, no `assets.deploy`.

## What it proves

- ox's zero-config Phoenix path (no `ox.toml`): apt Elixir 1.18.3 / OTP 27, `mix release`,
  the release start with `PHX_SERVER`, `RELEASE_TMP=/tmp` and `RELEASE_DISTRIBUTION=none`,
  `PhoenixLive.Release.migrate()` as the migrate step, postgres proposed from `postgrex`.
- LiveView websockets through Caddy, with `check_origin` pinned to `PUBLIC_URL` and the
  endpoint host taken from `PUBLIC_HOST`.
- Two sides of a zero-downtime switch running at once (distribution off, no node name clash).

## Zoo endpoints

- `GET /_zoo/health`: name, stack, server (from `PUBLIC_HOST`), release (`OX_RELEASE`, 12 chars),
  env (`OX_ENV`), uptime, start time, `build.built_at` (compile-time constant) and runtime.
- `GET /_zoo/probe`, one at a time (a second waits up to 5 s, then 429), each check capped at 5 s:
  - `postgres`: insert a `zoo_probe` row through Ecto, read it back, compare, delete, report the server version.
  - `pubsub`: subscribe to a random topic, broadcast a nonce, receive it.
  - `release`: release name and version (`RELEASE_NAME`/`RELEASE_VSN` from the release script), Elixir and OTP.
- CORS on `/_zoo/*` from `ZOO_PANEL_ORIGIN` (exact origin echo, `Vary: Origin`, preflight 204).
- Not a verifier, signer or chain member, so no `/_zoo/verify`, `/_zoo/trace` or signing code.

## Variables

| Name | Source | Notes |
|------|--------|-------|
| `PORT`, `HOST`, `OX_ENV`, `OX_RELEASE`, `PUBLIC_URL`, `PUBLIC_HOST` | provided | host and `check_origin` derive from `PUBLIC_HOST` / `PUBLIC_URL` |
| `DATABASE_URL` | provided (postgres) | |
| `SECRET_KEY_BASE` | yours, secret | at least 64 bytes: `mix phx.gen.secret`. Do not press Generate (43 characters, see below) |
| `ZOO_PANEL_ORIGIN` | yours, plain | `https://zoo-control.s1.zoo.sorv.dev` |

`SECRET_KEY_BASE` must be 64 bytes or more: `Plug.Session.COOKIE` raises
`cookie store expects conn.secret_key_base to be at least 64 bytes` on the first request with a
shorter one, so `config/runtime.exs` refuses to boot with a clear message instead. ox's
**Generate** button makes 43 characters, which would fail here.

## Tests

Needs a Postgres on 127.0.0.1 with a `postgres` role (trust auth, no password):

```console
$ DATABASE_URL=ecto://postgres@127.0.0.1:26094/phoenix_live_test mix test
Running ExUnit with seed: 735035, max_cases: 16

............
Finished in 0.2 seconds (0.00s async, 0.2s sync)

Result: 12 passed
```

Covered: server label, release cut, fingerprint vector (`915a`), health shape, a full probe
against Postgres and PubSub with the `zoo_probe` row cleaned up, missing-secret reporting, the
busy lock, CORS for a listed origin, an unlisted origin and a preflight, the LiveView counter
updating two views with presence, and the package-served JS.

The prod release was also built locally (`MIX_ENV=prod mix release`), migrated with
`bin/phoenix_live eval 'PhoenixLive.Release.migrate()'` and started with ox's start command: health
and probe answered, it listened only on 127.0.0.1, `/` redirected plain HTTP on the public host to
HTTPS and served 200 with `X-Forwarded-Proto: https`.

## ox check

```console
$ /tmp/oxz/ox check .
ox check /oxzoo-live/phoenix-live (manifest: none)

  app.start                  PHX_SERVER=true RELEASE_TMP=/tmp RELEASE_DISTRIBUTION=none _build/prod/rel/phoenix_live/bin/phoenix_live start detected:mix.exs
  build.install              mix local.hex --force && mix local.rebar --force && MIX_ENV=prod mix deps.get --only prod detected:mix.exs
  build.commands[0]          MIX_ENV=prod mix compile                             detected:mix.exs
  build.commands[1]          MIX_ENV=prod mix release                             detected:mix.exs
  build.migrate              RELEASE_TMP=/tmp _build/prod/rel/phoenix_live/bin/phoenix_live eval 'PhoenixLive.Release.migrate()' detected:lib/phoenix_live/release.ex
  packages                   elixir                                               detected:mix.exs
  packages                   erlang-dev                                           detected:mix.exs
  packages                   erlang-nox                                           detected:mix.exs
  services.postgres          postgres 18 (shared)                                 detected:mix.exs

  Provided by ox: PORT, HOST, OX_ENV, OX_PROJECT, OX_RELEASE, OX_DATA_DIR, PUBLIC_URL, PUBLIC_HOST, DATABASE_URL
  Set on the dashboard before the first deploy: SECRET_KEY_BASE, ZOO_PANEL_ORIGIN

Ready to deploy.
```
