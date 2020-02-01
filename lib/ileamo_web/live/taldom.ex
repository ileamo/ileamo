defmodule IleamoWeb.TaldomView do
  use Phoenix.LiveView

  def render(assigns) do
    IleamoWeb.PageView.render("taldom.html", assigns)
  end

  def mount(_session, socket) do
    Phoenix.PubSub.subscribe(Ileamo.PubSub, "mqtt", link: true)
    {:ok, assign(socket, temp: "0", humi: "0%", btemp: 0)}
  end

  def handle_info(mes, socket) do
    {:noreply, assign(socket, humi: inspect(mes))}
  end
end
