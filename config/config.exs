# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :ileamo,
  ecto_repos: [Ileamo.Repo]

# Configures the endpoint
config :ileamo, IleamoWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "0CKIK54ZX0SYu3h2vezGneaTbQt5wT0S0Ef5C/XNGjlwBuo1ZZDIcQuCGPWXTEnt",
  render_errors: [view: IleamoWeb.ErrorView, accepts: ~w(html json)],
  pubsub_server: Ileamo.PubSub,
  live_view: [signing_salt: "kZBLSYy9R+g6RL7zhs/3NM1m7m3FdhJ8"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
