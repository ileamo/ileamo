defmodule IleamoWeb.TaldomView do
  use Phoenix.LiveView
  @no_connection "Нет связи с домом!"

  def render(assigns) do
    IleamoWeb.PageView.render("taldom.html", assigns)
  end

  def mount(_session, socket) do
    Phoenix.PubSub.subscribe(Ileamo.PubSub, "mqtt", link: true)

    %{
      timer: {timer, _},
      btemp: {btemp, btemp_date},
      csq: {csq, csq_date},
      humi: {humi, humi_date},
      temp: {temp, temp_date}
    } = Ileamo.TaldomAgent.get_sensor(:all)

    if connected?(socket) do
      Process.send_after(self(), :timer, 1000)
    end

    {:ok,
     assign(socket,
       error: if(timer == "1", do: "", else: @no_connection),
       temp: temp,
       humi: humi,
       btemp: btemp,
       csq: csq,
       temp_date: temp_date,
       humi_date: humi_date,
       btemp_date: btemp_date,
       csq_date: csq_date,
       local_time: get_local_time()
     )}
  end

  def handle_info(:timer, socket) do
    Process.send_after(self(), :timer, 1000)
    {:noreply, assign(socket, local_time: get_local_time())}
  end

  def handle_info({:temp, {val, ts}}, socket) do
    {:noreply, assign(socket, temp: val, temp_date: ts, error: "")}
  end

  def handle_info({:humi, {val, ts}}, socket) do
    {:noreply, assign(socket, humi: val, humi_date: ts, error: "")}
  end

  def handle_info({:btemp, {val, ts}}, socket) do
    {:noreply, assign(socket, btemp: val, btemp_date: ts, error: "")}
  end

  def handle_info({:csq, {val, ts}}, socket) do
    {:noreply, assign(socket, csq: val, csq_date: ts, error: "")}
  end

  def handle_info({:timer, {"1", _}}, socket) do
    {:noreply, assign(socket, error: "")}
  end

  def handle_info({:timer, _}, socket) do
    {:noreply, assign(socket, error: @no_connection)}
  end

  def handle_info(mes, socket) do
    IO.inspect(mes, label: "Taldom")
    {:noreply, socket}
  end

  def get_local_time() do
    (NaiveDateTime.utc_now()
     |> NaiveDateTime.truncate(:second)
     |> NaiveDateTime.add(3 * 60 * 60, :second)
     |> NaiveDateTime.to_string()) <> " MSK"
  end
end
