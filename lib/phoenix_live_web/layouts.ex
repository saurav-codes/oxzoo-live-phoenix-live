defmodule PhoenixLiveWeb.Layouts do
  use Phoenix.Component

  def root(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="csrf-token" content={Phoenix.Controller.get_csrf_token()} />
        <title>phoenix-live</title>
        <link rel="stylesheet" href="/assets/app.css" />
        <script defer src="/vendor/phoenix/phoenix.min.js"></script>
        <script defer src="/vendor/lv/phoenix_live_view.min.js"></script>
        <script defer src="/assets/app.js"></script>
      </head>
      <body>{@inner_content}</body>
    </html>
    """
  end
end
