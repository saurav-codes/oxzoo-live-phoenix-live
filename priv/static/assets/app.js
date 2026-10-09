// phoenix.min.js and phoenix_live_view.min.js (served from the packages) define
// the Phoenix and LiveView globals; deferred scripts run in order.
window.addEventListener("DOMContentLoaded", () => {
  const csrf = document.querySelector("meta[name='csrf-token']").getAttribute("content")
  const liveSocket = new LiveView.LiveSocket("/live", Phoenix.Socket, { params: { _csrf_token: csrf } })
  liveSocket.connect()
})
