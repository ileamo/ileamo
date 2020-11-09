defmodule IleamoWeb.Router do
  use IleamoWeb, :router
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :put_root_layout, {IleamoWeb.LayoutView, "root.html"}
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", IleamoWeb do
    pipe_through :browser

    live "/", TaldomLive
  end

  # Other scopes may use custom stacks.
  # scope "/api", IleamoWeb do
  #   pipe_through :api
  # end
end
