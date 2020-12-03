defmodule Ileamo.PlotAgent do
  use Agent
  require Logger

  def start_link(_) do
    Agent.start_link(
      fn ->
        %{}
      end,
      name: __MODULE__
    )
  end

  @delta 60 * 60
  def request_plot(key, pid) do
    Agent.cast(__MODULE__, fn state ->
      with {svg, ts} <- state[key],
           true <- :os.system_time(:seconds) - ts < @delta do
        GenServer.cast(pid, {:plot_svg, svg})
        state
      else
        _ ->
          svg = get_svg(key)
          GenServer.cast(pid, {:plot_svg, svg})
          state |> Map.put(key, {svg, :os.system_time(:seconds)})
      end
    end)
  end

  defp get_svg(key) do
    case get_data_from_zabbix(key) do
      data = [_ | _] ->
        dataset = Contex.Dataset.new(data)

        Contex.Plot.new(dataset, Contex.LinePlot, 600, 300,
          smoothed: true,
          colour_palette: ["1d4ed8"]
        )
        |> Contex.Plot.plot_options(%{left_margin: 40})
        |> Contex.Plot.to_svg()

      _ ->
        ""
    end
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
