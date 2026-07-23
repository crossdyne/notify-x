import Config

config :swoosh, :api_client, false

smtp_relay = System.get_env("SMTP_RELAY") || raise "SMTP_RELAY not set"
smtp_username = System.get_env("SMTP_USERNAME") || raise "SMTP_USERNAME not set"
smtp_password = System.get_env("SMTP_PASSWORD") || raise "SMTP_PASSWORD not set"
smtp_from = System.get_env("SMTP_FROM_EMAIL") || raise "SMTP_FROM_EMAIL not set"
kafka_brokers = System.get_env("KAFKA_BROKERS") || raise "KAFKA_BROKERS not set"
kafka_topic = System.get_env("KAFKA_TOPIC") || raise "KAFKA_TOPIC not set"
kafka_group = System.get_env("KAFKA_GROUP_ID") || raise "KAFKA_GROUP_ID not set"

config :notifier, Notifier.Mailer,
  adapter: Swoosh.Adapters.SMTP,
  relay: smtp_relay,
  port: String.to_integer(System.get_env("SMTP_PORT") || "465"),
  username: smtp_username,
  password: smtp_password,
  ssl: true,
  tls: :never,
  auth: :always,
  retries: 2,
  no_mx_lookups: false,
  sockopts: [
    versions: [:"tlsv1.2", :"tlsv1.3"],
    verify: :verify_peer,
    cacerts: :public_key.cacerts_get(),
    depth: 3,
    customize_hostname_check: [
      match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
    ],
    server_name_indication: ~c"smtp.yandex.ru"
  ]

config :notifier, :from_email, smtp_from

config :notifier, Notifier.KafkaConsumer,
  brokers: kafka_brokers,
  topic: kafka_topic,
  group_id: kafka_group
