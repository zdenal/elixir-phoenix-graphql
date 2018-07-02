defmodule PlateSlateWeb.Router do
  use PlateSlateWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :admin_auth do
    plug PlateSlateWeb.AdminAuth
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug PlateSlateWeb.Context
  end

  scope "/" do
    pipe_through :api

    forward "/api", Absinthe.Plug,
      schema: PlateSlateWeb.Schema

    forward "/graphiql", Absinthe.Plug.GraphiQL,
      schema: PlateSlateWeb.Schema,
      socket: PlateSlateWeb.UserSocket
  end

  scope "/admin", PlateSlateWeb do
    pipe_through :browser

    resources "/session", SessionController,
      only: [:new, :create, :delete],
      singleton: true
  end
  scope "/admin", PlateSlateWeb do
    pipe_through [:browser, :admin_auth]

    resources "/items", ItemController
  end
end
