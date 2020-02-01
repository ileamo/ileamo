defmodule IleamoWeb.PageController do
  use IleamoWeb, :controller

  def index(conn, _) do
    Phoenix.LiveView.Controller.live_render(conn, IleamoWeb.TaldomView, session: %{})
  end
end
