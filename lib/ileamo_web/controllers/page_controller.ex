defmodule IleamoWeb.PageController do
  use IleamoWeb, :controller

  def index(conn, _) do
    render(conn, "index.html")
  end

  def login(conn, %{"password" => psw}) do
    case auth(psw) do
      :ok ->
        token = Ileamo.Token.sign(conn, 177)

        conn
        |> put_session(:token, token)
        |> redirect(to: Routes.live_path(conn, IleamoWeb.TaldomLive))

      _ ->
        conn
        |> put_session(:token, "")
        |> redirect(to: Routes.page_path(conn, :index))
    end
  end

  @hash <<235, 29, 155, 197, 252, 136, 214, 22, 28, 172, 249, 37, 107, 183, 73, 16, 59, 16, 63,
          32>>

  defp auth(psw) do
    case :crypto.hash(:sha, psw) do
      @hash -> :ok
      _ -> :error
    end
  end
end
