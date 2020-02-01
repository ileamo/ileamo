defmodule IleamoWeb.TaldomView do
  use Phoenix.LiveView

  def render(assigns) do
    IleamoWeb.PageView.render("taldom.html", assigns)
  end

  def mount(_session, socket) do
    Phoenix.PubSub.subscribe(Ileamo.PubSub, "mqtt", link: true)
    {:ok, assign(socket, temp: 0, humi: 0, btemp: 0, csq: 99)}
  end

  def handle_info({:temp, val}, socket) do
    {:noreply, assign(socket, temp: inspect(val))}
  end

  def handle_info({:humi, val}, socket) do
    {:noreply, assign(socket, humi: inspect(val))}
  end

  def handle_info({:btemp, val}, socket) do
    {:noreply, assign(socket, btemp: inspect(val))}
  end

  def handle_info({:csq, val}, socket) do
    {:noreply, assign(socket, csq: inspect(val))}
  end

  def handle_info(mes, socket) do
    IO.inspect(mes, label: "Taldom")
    {:noreply, socket}
  end
end
