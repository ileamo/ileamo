defmodule IleamoWeb.TaldomLive do
  use IleamoWeb, :live_view
  require Logger
  alias Ileamo.TaldomAgent, as: TA

  @no_connection "Нет связи с домом!"
  @plots [
    {"TEMP[taldom]", "Температура в доме"},
    {"btemp[taldom]", "Температура в подполе"}
  ]

  @waiting ~E"""
  <div class="relative flex justify-center items-center">
    <svg class="animate-spin text-green-700" width=150 height=150
      xmlns="http://www.w3.org/2000/svg"
      fill="none" viewBox="0 0 100 100" stroke="CurrentColor"
    >
      <path d="M10,50 a1,1 0 0,0 80,0" style="stroke-width: 5" />
    </svg>
  </div>
  """

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
        } = TA.get_sensor(:all)

        if connected?(socket) do
          Process.send_after(self(), :timer, 1000)
        end

        {plot_key, plot_header} = get_next_plot()

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
           temp_trend: TA.get_sensor_trend(:temp, 0.09),
           humi_trend: TA.get_sensor_trend(:humi, 0.9),
           btemp_trend: TA.get_sensor_trend(:btemp, 0.09),
           temp_history: TA.get_sensor_history(:temp),
           humi_history: TA.get_sensor_history(:humi),
           btemp_history: TA.get_sensor_history(:btemp),
           temp_history_show: false,
           humi_history_show: false,
           btemp_history_show: false,
           csq_history: TA.get_sensor_history(:csq),
           local_time: get_local_time(),
           plot: @waiting,
           plot_key: plot_key,
           plot_header: plot_header,
           bounce: false,
           owm_temp: Ileamo.OwmAgent.get_temp("taldom,ru")
         )}

      _ ->
        {:ok, redirect(socket, to: "/login")}
    end
  end

  @impl true
  def handle_info(:after_mount, socket = %{assigns: %{plot_key: key}}) do
    Ileamo.PlotAgent.request_plot(key, self())
    {:noreply, assign(socket, plot: @waiting)}
  end

  @impl true
  def handle_info(:timer, socket) do
    Process.send_after(self(), :timer, 1000)
    {:noreply, assign(socket, local_time: get_local_time())}
  end

  def handle_info(:bounce, socket = %{assigns: %{bounce: bounce}}) do
    case bounce do
      false ->
        Process.send_after(self(), :bounce, 3000)
        {:noreply, assign(socket, bounce: true)}

      true ->
        {:noreply, assign(socket, bounce: nil)}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_info({:temp, {val, ts}}, socket) do
    trend = TA.get_sensor_trend(:temp, 0.09)
    history = TA.get_sensor_history(:temp)

    {:noreply,
     assign(socket, temp: val, temp_date: ts, temp_trend: trend, temp_history: history, error: "")}
  end

  def handle_info({:humi, {val, ts}}, socket) do
    trend = TA.get_sensor_trend(:humi, 0.9)
    history = TA.get_sensor_history(:humi)

    {:noreply,
     assign(socket, humi: val, humi_date: ts, humi_trend: trend, humi_history: history, error: "")}
  end

  def handle_info({:btemp, {val, ts}}, socket) do
    trend = TA.get_sensor_trend(:btemp, 0.09)
    history = TA.get_sensor_history(:btemp)

    {:noreply,
     assign(socket,
       btemp: val,
       btemp_date: ts,
       btemp_trend: trend,
       btemp_history: history,
       error: ""
     )}
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

  @impl true
  def handle_event("plot-content", %{"key" => key}, socket) do
    {plot_key, plot_header} = get_next_plot(key)
    Ileamo.PlotAgent.request_plot(plot_key, self())
    {:noreply, assign(socket, plot_key: plot_key, plot_header: plot_header, plot: @waiting)}
  end

  def handle_event("temp-history", _, socket = %{assigns: %{temp_history_show: on}}) do
    {:noreply, assign(socket, temp_history_show: !on)}
  end

  def handle_event("btemp-history", _, socket = %{assigns: %{btemp_history_show: on}}) do
    {:noreply, assign(socket, btemp_history_show: !on)}
  end

  def handle_event("humi-history", _, socket = %{assigns: %{humi_history_show: on}}) do
    {:noreply, assign(socket, humi_history_show: !on)}
  end

  def handle_event(event, params, socket) do
    Logger.error("Unrecognized event: #{inspect(event)}(#{inspect(params)})")
    {:noreply, socket}
  end

  @impl true
  def handle_cast({:plot_svg, svg}, socket = %{assigns: %{bounce: bounce}}) do
    if bounce == false do
      Process.send_after(self(), :bounce, 5000)
    end

    {:noreply, assign(socket, plot: svg)}
  end

  def handle_cast(_, socket) do
    {:noreply, socket}
  end

  def get_local_time() do
    (NaiveDateTime.utc_now()
     |> NaiveDateTime.truncate(:second)
     |> NaiveDateTime.add(3 * 60 * 60, :second)
     |> NaiveDateTime.to_string()) <> " MSK"
  end

  defp get_next_plot() do
    @plots |> List.first()
  end

  defp get_next_plot(key) do
    {plot, _} =
      @plots
      |> Enum.reduce_while(
        {List.first(@plots), false},
        fn
          el, {_plot, true} -> {:halt, {el, true}}
          {^key, _}, {plot, _} -> {:cont, {plot, true}}
          _, acc -> {:cont, acc}
        end
      )

    plot
  end

  def get_trend_svg(trend) do
    if trend in [:up, :down] do
      render(IleamoWeb.PageView, "arrow-#{trend}.html",
        class: "ml-2 w-8 h-8 fill-current text-green-800"
      )
    end
  end
end
