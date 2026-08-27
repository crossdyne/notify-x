import Config

config :logger, level: :info
config :swoosh, local: false
config :swoosh, api_client: Swoosh.ApiClient.Req
