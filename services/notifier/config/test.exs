import Config

config :logger, level: :warning

config :notifier, Notifier.Mailer, adapter: Swoosh.Adapters.Test
config :swoosh, :api_client, false
