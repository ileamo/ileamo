defmodule IleamoWeb.TaldomLive do
  use IleamoWeb, :live_view
  require Logger
  @no_connection "Нет связи с домом!"
  @plots [
    {"TEMP[taldom]", "Температура в доме"},
    {"btemp[taldom]", "Температура в подполе"}
  ]

  @waiting ~E"""
  <div class="relative flex justify-center items-center">
    <svg class="animate-spin text-green-800" width=150 height=150
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
        } = Ileamo.TaldomAgent.get_sensor(:all)

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
           local_time: get_local_time(),
           plot: @waiting,
           plot_key: plot_key,
           plot_header: plot_header
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

  @impl true
  def handle_event("plot-content", %{"key" => key}, socket) do
    {plot_key, plot_header} = get_next_plot(key)
    Ileamo.PlotAgent.request_plot(plot_key, self())
    {:noreply, assign(socket, plot_key: plot_key, plot_header: plot_header, plot: @waiting)}
  end

  def handle_event(event, _, socket) do
    Logger.error("Unrecognized event: #{inspect(event)}")
    {:noreply, socket}
  end

  @impl true
  def handle_cast({:plot_svg, svg}, socket) do
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
end
