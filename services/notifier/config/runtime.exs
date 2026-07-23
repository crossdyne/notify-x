import Config

Dotenvy.source!(".env")

config :notifier, Notifier.Mailer,
  adapter: Swoosh.Adapters.SMTP,
  relay: Dotenvy.env!("SMTP_RELAY"),
  port: 465,
  username: Dotenvy.env!("SMTP_USERNAME"),
  password: Dotenvy.env!("SMTP_PASSWORD"),
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

config :notifier, :from_email, Dotenvy.env!("SMTP_FROM_EMAIL")

config :notifier, Notifier.KafkaConsumer,
  brokers: Dotenvy.env!("KAFKA_BROKERS"),
  topic: Dotenvy.env!("KAFKA_TOPIC"),
  group_id: Dotenvy.env!("KAFKA_GROUP_ID")
