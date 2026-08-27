import Config

config :notifier,
  env: Mix.env()

config :logger, level: :info

import_config "#{config_env()}.exs"
