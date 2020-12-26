defmodule Ileamo.TaldomAgent do
  use Agent

  def start_link(_) do
    Agent.start_link(
      fn ->
        %{
          timer: %{val: {"1", ""}},
          temp: %{val: {"", ""}},
          humi: %{val: {"", ""}},
          btemp: %{val: {"", ""}},
          csq: %{val: {"", ""}}
        }
        |> Enum.map(fn {sensor, map} -> {sensor, Map.put(map, :cb, [])} end)
        |> Enum.into(%{})
      end,
      name: __MODULE__
    )
  end

  def get_sensor(:all) do
    Agent.get(__MODULE__, fn state ->
      state
      |> Enum.map(fn {sensor, %{val: val}} -> {sensor, val} end)
      |> Enum.into(%{})
    end)
  end

  def get_sensor(sensor) do
    Agent.get(__MODULE__, fn state -> state[sensor][:val] end)
  end

  def get_sensor_trend(sensor, eq) do
    Agent.get(__MODULE__, fn state ->
      with %{val: {val, _ts}, cb: cb} <- state[sensor],
           {val, _} <- Float.parse(val),
           cb = [_ | _] <-
             cb
             |> Enum.map(fn str ->
               case Float.parse(str) do
                 {v, _} -> v
                 _ -> :error
               end
             end)
             |> Enum.filter(fn
               f when is_float(f) -> true
               _ -> false
             end) do
        avg = Enum.sum(cb) / length(cb)
        diff = val - avg

        cond do
          diff > eq -> :up
          diff < -eq -> :down
          true -> :eq
        end
      else
        _ -> :no_data
      end
    end)
  end

  def get_sensor_history(sensor) do
    Agent.get(__MODULE__, fn state ->
      with %{cb: cb} when is_list(cb) <- state[sensor] do
        Enum.reverse(cb)
      else
        _ -> []
      end
    end)
  end

  def update_sensor(sensor, val = {curr_val, _ts}) do
    Phoenix.PubSub.broadcast(Ileamo.PubSub, "mqtt", {sensor, val})

    Agent.update(__MODULE__, fn
      state = %{^sensor => %{cb: cb}} ->
        new_cb =
          case {curr_val, cb} do
            {v, [v | _]} -> cb
            {v, [p, v, p | rest]} -> [v, p | rest]
            _ -> [curr_val | cb] |> Enum.take(8)
          end

        state
        |> Map.put(sensor, %{val: val, cb: new_cb})
    end)
  end
end
