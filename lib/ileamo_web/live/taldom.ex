defmodule IleamoWeb.TaldomLive do
  use IleamoWeb, :live_view
  require Logger
  @no_connection "Нет связи с домом!"

  @impl true
  def mount(_params, session, socket) do
    case Ileamo.Token.verify(IleamoWeb.Endpoint, session["token"]) do
      {:ok, _} ->
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

        send(self(), :after_mount)

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
           local_time: get_local_time(),
           plot: ""
         )}

      _ ->
        {:ok, redirect(socket, to: "/login")}
    end
  end

  @impl true
  def handle_info(:after_mount, socket) do
    output =
      case get_data_from_zabbix("btemp[taldom]") do
        data = [_ | _] ->
          dataset = Contex.Dataset.new(data)

          Contex.Plot.new(dataset, Contex.LinePlot, 600, 300, smoothed: true)
          |> Contex.Plot.plot_options(%{left_margin: 40})
          |> Contex.Plot.titles("Температура в доме", "")
          |> Contex.Plot.to_svg()

        _ ->
          ""
      end

    {:noreply, assign(socket, plot: output)}
  end

  @impl true
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

  def handle_info(_mes, socket) do
    {:noreply, socket}
  end

  def get_local_time() do
    (NaiveDateTime.utc_now()
     |> NaiveDateTime.truncate(:second)
     |> NaiveDateTime.add(3 * 60 * 60, :second)
     |> NaiveDateTime.to_string()) <> " MSK"
  end

  @tz 3 * 60 * 60
  defp get_data_from_zabbix(key) do
    current_time = :os.system_time(:seconds)

    with :ok <- Zabbix.API.create_client("https://84.253.109.139:10443", 30_000),
         {:ok, _auth} <- Zabbix.API.login("ileamo", "ileamo4IoT"),
         {:ok, %{"result" => [%{"itemid" => itemid, "key_" => ^key}]}} <-
           Zabbix.API.call("item.get", %{
             host: "NSG1820MC_1701006070",
             output: ["itemid", "key_"],
             search: %{key_: key},
             searchWildcardsEnabled: true
           }),
         {:ok, %{"result" => list}} <-
           Zabbix.API.call("history.get", %{
             itemids: itemid,
             history: 0,
             time_from: current_time - 60 * 60 * 24 * 7
           }) do
      list =
        list
        |> Enum.map(fn %{"clock" => clock, "value" => value} ->
          {String.to_integer(clock) + @tz, String.to_float(value)}
        end)
        |> Enum.sort_by(fn {t, _} -> t end)

      case list do
        [_] ->
          list

        [{start, val} | tail] ->
          {stop, _last_value} = List.last(tail)
          delta = (stop - start) / 60

          tail
          |> Enum.chunk_while(
            {start, [{start, val}]},
            fn el = {tm, _val}, {start, chunk} ->
              if tm - start < delta do
                {:cont, {start, [el | chunk]}}
              else
                {:cont, avg(chunk), {tm, [el]}}
              end
            end,
            fn {_start, [{_, v} | _] = chunk} ->
              {:cont, avg([{current_time + @tz, v} | chunk]), {}}
            end
          )
          |> IO.inspect()

        _ ->
          []
      end
    else
      res ->
        Logger.error("Can't get data from Zabbix: #{inspect(res)}")
        []
    end
  end

  defp avg(chunk) do
    length = length(chunk)

    {x, y} =
      chunk
      |> Enum.reduce(fn {_x, y}, {sx, sy} -> {sx, sy + y} end)

    {x |> DateTime.from_unix!(), y / length}
  end
end
