defmodule IleamoWeb.TaldomView do
  use Phoenix.LiveView

  def render(assigns) do
    IleamoWeb.PageView.render("taldom.html", assigns)
  end

  def mount(_session, socket) do
    Phoenix.PubSub.subscribe(Ileamo.PubSub, "mqtt", link: true)

    %{
      btemp: {btemp, btemp_date},
      csq: {csq, csq_date},
      humi: {humi, humi_date},
      temp: {temp, temp_date}
    } = Ileamo.TaldomAgent.get_sensor(:all)

    {:ok,
     assign(socket,
       temp: temp,
       humi: humi,
       btemp: btemp,
       csq: csq,
       temp_date: temp_date,
       humi_date: humi_date,
       btemp_date: btemp_date,
       csq_date: csq_date
     )}
  end

  def handle_info({:temp, {val, ts}}, socket) do
    {:noreply, assign(socket, temp: val, temp_date: ts)}
  end

  def handle_info({:humi, {val, ts}}, socket) do
    {:noreply, assign(socket, humi: val, temp_date: ts)}
  end

  def handle_info({:btemp, {val, ts}}, socket) do
    {:noreply, assign(socket, btemp: val, temp_date: ts)}
  end

  def handle_info({:csq, {val, ts}}, socket) do
    {:noreply, assign(socket, csq: val, temp_date: ts)}
  end

  def handle_info(mes, socket) do
    IO.inspect(mes, label: "Taldom")
    {:noreply, socket}
  end
end
