defmodule Ileamo.MQTT do
  def start_mqtt() do
    Tortoise.Supervisor.start_child(
      client_id: "ileamo",
      server: {Tortoise.Transport.Tcp, host: "84.253.109.156", port: 1883},
      handler: {Ileamo.MQTT.Handler, []},
      user_name: "imosunov",
      password: "i0708",
      subscriptions: [{"/ru/nsg/imosunov/taldom/#", 0}]
    )
  end
end

defmodule Ileamo.MQTT.Handler do
  use Tortoise.Handler

  def init(args) do
    {:ok, args}
  end

  def connection(status, state) do
    IO.inspect {status, state}, label: "Connection"
    # `status` will be either `:up` or `:down`; you can use this to
    # inform the rest of your system if the connection is currently
    # open or closed; tortoise should be busy reconnecting if you get
    # a `:down`
    {:ok, state}
  end

  # #  topic filter room/+/temp
  # def handle_message(["room", room, "temp"], payload, state) do
  #   # :ok = Temperature.record(room, payload)
  #   {:ok, state}
  # end

  def handle_message(topic, payload, state) do
    IO.inspect {topic, payload, state}, label: "Message"
    # unhandled message! You will crash if you subscribe to something
    # and you don't have a 'catch all' matcher; crashing on unexpected
    # messages could be a strategy though.

    Phoenix.PubSub.broadcast(Ileamo.PubSub, "mqtt", inspect(payload))
    {:ok, state}
  end

  def subscription(status, topic_filter, state) do
    IO.inspect {status, topic_filter, state}, label: "Subscription"
    {:ok, state}
  end

  def terminate(reason, state) do
    IO.inspect {reason, state}, label: "Terminaye"
    # tortoise doesn't care about what you return from terminate/2,
    # that is in alignment with other behaviours that implement a
    # terminate-callback
    :ok
  end
end
