defmodule Ileamo.TaldomAgent do
  use Agent
  alias CircularBuffer, as: CB
  @cb_size 10

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
        |> Enum.map(fn {sensor, map} -> {sensor, Map.put(map, :cb, CB.new(@cb_size))} end)
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
             CB.to_list(cb)
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
      with %{val: {val, _ts}, cb: cb} <- state[sensor] do
        CB.to_list(cb) ++ [val]
      else
        _ -> []
      end
    end)
  end

  def update_sensor(sensor, val = {curr_val, _ts}) do
    Phoenix.PubSub.broadcast(Ileamo.PubSub, "mqtt", {sensor, val})

    Agent.update(__MODULE__, fn
      state = %{^sensor => %{val: {prev_val, _ts}, cb: cb}} ->
        new_cb =
          cond do
            curr_val == prev_val -> cb
            true -> CB.insert(cb, prev_val)
          end

        state
        |> Map.put(sensor, %{val: val, cb: new_cb})
    end)
  end
end
