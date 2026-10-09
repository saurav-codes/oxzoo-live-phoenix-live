defmodule PhoenixLiveWeb.CounterLive do
  @moduledoc "A shared counter kept in Postgres, pushed over PubSub, with live viewer presence."
  use Phoenix.LiveView
  alias PhoenixLive.{Counter, Zoo}
  alias PhoenixLiveWeb.Presence

  @viewers "viewers"
  @min_click_ms 100

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(PhoenixLive.PubSub, Counter.topic())
      Phoenix.PubSub.subscribe(PhoenixLive.PubSub, @viewers)

      {:ok, _} =
        Presence.track(self(), @viewers, socket.id, %{joined_at: System.system_time(:second)})
    end

    {:ok,
     assign(socket,
       count: Counter.get(),
       viewers: viewers(),
       last_click: nil,
       zoo: Zoo.identity()
     )}
  end

  @impl true
  def handle_event("inc", _params, socket) do
    now = System.monotonic_time(:millisecond)

    last = socket.assigns.last_click

    if last == nil or now - last >= @min_click_ms do
      {:noreply, assign(socket, count: Counter.increment(), last_click: now)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:count, value}, socket),
    do: {:noreply, assign(socket, count: max(value, socket.assigns.count))}

  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff"}, socket),
    do: {:noreply, assign(socket, viewers: viewers())}

  defp viewers, do: map_size(Presence.list(@viewers))

  @impl true
  def render(assigns) do
    ~H"""
    <main>
      <h1>phoenix-live</h1>
      <p class="muted">{@zoo.stack} on {@zoo.server}, release {@zoo.release}</p>
      <section class="card">
        <p class="count" id="count">{@count}</p>
        <button id="inc" phx-click="inc">+1 for everyone</button>
        <p id="viewers">{@viewers} {if @viewers == 1, do: "viewer", else: "viewers"} online</p>
      </section>
      <p class="muted">The count lives in Postgres; every click is broadcast over Phoenix.PubSub to all open tabs, and Phoenix.Presence counts the tabs.
        <a href="/_zoo/health">health</a> <a href="/_zoo/probe">probe</a></p>
    </main>
    """
  end
end
