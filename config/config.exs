# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :bitcoin,
  ecto_repos: [Bitcoin.Repo]

# Configures the endpoint
config :bitcoin, BitcoinWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "v1rMYmfR5FvNmxvwBEcxnGH0XgBfxzZr8Ufz09x4xr7ioUmciRARHsln6uVC6baY",
  render_errors: [view: BitcoinWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Bitcoin.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:user_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
