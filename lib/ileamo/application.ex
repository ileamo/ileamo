defmodule Ileamo.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      Ileamo.Repo,
      IleamoWeb.Endpoint,

      {Phoenix.PubSub, [name: Ileamo.PubSub, adapter: Phoenix.PubSub.PG2]},
      Ileamo.TaldomAgent,
      Ileamo.PlotAgent
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Ileamo.Supervisor]
    Supervisor.start_link(children, opts)
    Ileamo.MQTT.start_mqtt()
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    IleamoWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
