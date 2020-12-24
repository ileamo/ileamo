defmodule Ileamo.OwmAgent do
  use Agent
  require Logger

  @owp_url "api.openweathermap.org/data/2.5/weather"
  @appid "406064c1e6b6eadc1f567d2623cd1f7e"

  def start_link(_) do
    Agent.start_link(
      fn ->
        %{}
      end,
      name: __MODULE__
    )
  end

  @delta 60 * 60
  def get_temp(city) do
    Agent.get_and_update(__MODULE__, fn state ->
      curr_ts = :os.system_time(:seconds)


      case state[city] do
        %{ts: ts, weather: %{temp: temp}} when curr_ts - ts < @delta ->
          {temp, state}

        _ ->
          weather = get_current_weather(city)
          {weather[:temp], Map.put(state, city, %{ts: curr_ts, weather: weather})}
      end
    end)
  end

  defp get_current_weather(city) do
    with {:ok, %{body: body}} when is_binary(body) <-
           HTTPoison.get("#{@owp_url}?q=#{city}&units=metric&APPID=#{@appid}"),
         {:ok, %{"main" => %{"temp" => temp}}} <- Jason.decode(body) do
      %{temp: temp}
    else
      res ->
        Logger.warn("Can't get weather for #{city}: #{inspect(res)}")
        %{}
    end
  end
end
