defmodule Ileamo.TaldomAgent do
  use Agent

  def start_link(_) do
    Agent.start_link(fn -> %{temp: "", humi: "", btemp: "", csq: 99} end, name: __MODULE__)
  end

  def get_sensor(:all) do
    Agent.get(__MODULE__, fn state -> state end)
  end

  def get_sensor(sensor) do
    Agent.get(__MODULE__, fn state -> state[sensor] end)
  end

  def update_sensor(sensor, val) do
    Phoenix.PubSub.broadcast(Ileamo.PubSub, "mqtt", {sensor, val})
    Agent.update(__MODULE__, fn state -> state |> Map.put(sensor, val) end)
  end
end
