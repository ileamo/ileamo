defmodule IleamoWeb.PageController do
  use IleamoWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
