defmodule Ileamo.MQTT do
  def start_mqtt() do
    Tortoise.Supervisor.start_child(
      client_id: random_string(16),
      server: {Tortoise.Transport.Tcp, host: "84.253.109.156", port: 1883},
      handler: {Ileamo.MQTT.Handler, []},
      user_name: "imosunov",
      password: "i0708",
      subscriptions: [{"/ru/nsg/imosunov/taldom/#", 0}]
    )
  end

  defp random_string(length) do
    :crypto.strong_rand_bytes(length) |> Base.url_encode64() |> binary_part(0, length)
  end
end

defmodule Ileamo.MQTT.Handler do
  use Tortoise.Handler
  require Logger

  def init(args) do
    {:ok, args}
  end

  def connection(status, state) do
    # `status` will be either `:up` or `:down`; you can use this to
    # inform the rest of your system if the connection is currently
    # open or closed; tortoise should be busy reconnecting if you get
    # a `:down`
    {:ok, state}
  end

  defp handle_taldom(payload, sensor) do
    #Logger.info("Датчик #{sensor} (#{inspect(payload)})")

    with {:ok, payload} <- Jason.decode(payload),
         {val, ts} when is_binary(val) and is_binary(ts) <-
           {payload["sensor_value"], payload["timestamp"]} do
      Ileamo.TaldomAgent.update_sensor(sensor, {val, ts})
    end
  end

  def handle_message(["", "ru", "nsg", "imosunov", "taldom", "kitchen", "temp"], payload, state) do
    handle_taldom(payload, :temp)
    {:ok, state}
  end

  def handle_message(["", "ru", "nsg", "imosunov", "taldom", "kitchen", "humi"], payload, state) do
    handle_taldom(payload, :humi)
    {:ok, state}
  end

  def handle_message(["", "ru", "nsg", "imosunov", "taldom", "basement", "temp"], payload, state) do
    handle_taldom(payload, :btemp)
    {:ok, state}
  end

  def handle_message(["", "ru", "nsg", "imosunov", "taldom", "csq"], payload, state) do
    handle_taldom(payload, :csq)
    {:ok, state}
  end

  def handle_message(["", "ru", "nsg", "imosunov", "taldom", "timer"], payload, state) do
    Ileamo.TaldomAgent.update_sensor(:timer, {payload, ""})
    {:ok, state}
  end

  def handle_message(topic, _payload, state) do
    Logger.info("Необработанное сообщение: #{inspect(topic)}")
    # unhandled message! You will crash if you subscribe to something
    # and you don't have a 'catch all' matcher; crashing on unexpected
    # messages could be a strategy though.

    {:ok, state}
  end

  def subscription(status, topic_filter, state) do
    IO.inspect({status, topic_filter, state}, label: "Subscription")
    {:ok, state}
  end

  def terminate(reason, state) do
    IO.inspect({reason, state}, label: "Terminate")
    # tortoise doesn't care about what you return from terminate/2,
    # that is in alignment with other behaviours that implement a
    # terminate-callback
    :ok
  end
end
