defmodule HexWeb.Router do
  use Plug.Router
  import Plug.Conn
  import HexWeb.Plug
  alias HexWeb.Plugs
  alias HexWeb.Config

  plug Plugs.Exception
  plug Plugs.Forwarded
  plug Plugs.Redirect, ssl: &Config.use_ssl/0, redirect: [&Config.app_host/0], to: &Config.url/0

  plug :fetch

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Static, at: "/static", from: :hex_web

  plug :match
  plug :dispatch

  # TODO: favicon

  if Mix.env != :prod do
    get "registry.ets.gz" do
      HexWeb.Config.store.registry(conn)
    end

    get "tarballs/:ball" do
      HexWeb.Config.store.tar(conn, ball)
    end
  end

  get "installs/hex.ez" do
    case List.first get_req_header(conn, "user-agent") do
      "Mix/" <> version ->
        latest = HexWeb.Install.latest(version)
      _ ->
        latest = nil
    end

    if latest do
      url = "/installs/#{latest}/hex.ez"
    else
      url = "/installs/hex.ez"
    end

    url = HexWeb.Config.cdn_url <> url

    conn
    |> cache([], [:public, "max-age": 60*60])
    |> redirect(url)
  end

  forward "/api", to: HexWeb.API.Router

  match _ do
    HexWeb.Web.Router.call(conn, [])
  end

  defp fetch(conn, _opts) do
    fetch_params(conn)
  end
end
