defmodule IleamoWeb.PageController do
  use IleamoWeb, :controller

  def index(conn, _) do
      render(conn, "index.html")
  end

  def login(conn, params) do
      IO.inspect(params)
      render(conn, "index.html")
  end
end
