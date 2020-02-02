defmodule IleamoWeb.TaldomView do
  use Phoenix.LiveView

  def render(assigns) do
    IleamoWeb.PageView.render("taldom.html", assigns)
  end

  def mount(_session, socket) do
    Phoenix.PubSub.subscribe(Ileamo.PubSub, "mqtt", link: true)
    %{btemp: btemp, csq: csq, humi: humi, temp: temp} = Ileamo.TaldomAgent.get_sensor(:all)
    {:ok, assign(socket, temp: temp, humi: humi, btemp: btemp, csq: csq)}
  end

  def handle_info({:temp, val}, socket) do
    {:noreply, assign(socket, temp: val)}
  end

  def handle_info({:humi, val}, socket) do
    {:noreply, assign(socket, humi: val)}
  end

  def handle_info({:btemp, val}, socket) do
    {:noreply, assign(socket, btemp: val)}
  end

  def handle_info({:csq, val}, socket) do
    {:noreply, assign(socket, csq: val)}
  end

  def handle_info(mes, socket) do
    IO.inspect(mes, label: "Taldom")
    {:noreply, socket}
  end
end
