# Notifier

Микросервис уведомлений организации [Crossdyne](https://github.com/crossdyne).  
Простой и надёжный консьюмер Kafka → SMTP. Получает JSON-сообщения из Kafka-топика и отправляет email-письма через заданный SMTP-релей.

## Что делает

- Подключается к Kafka как consumer в заданной consumer group.
- Слушает указанный топик через [Broadway](https://github.com/dashbitco/broadway) + [BroadwayKafka](https://github.com/dashbitco/broadway_kafka).
- При получении сообщения парсит JSON, извлекает адресата, тему и тело письма.
- Отправляет письмо через SMTP-адаптер [Swoosh](https://github.com/swoosh/swoosh).
- Работает как supervised OTP-приложение — падает gracefully и перезапускается.

## Архитектура

```
┌─────────────┐     ┌─────────────────┐     ┌─────────────┐
│   Kafka     │────>│ Notifier Service│────>│   SMTP      │
│   (topic)   │     │  (Broadway)     │     │  (Yandex)   │
└─────────────┘     └─────────────────┘     └─────────────┘
```

Основные модули:

| Модуль | Назначение |
|--------|------------|
| `Notifier.Application` | Точка входа. Запускает супервизор и KafkaConsumer. |
| `Notifier.KafkaConsumer` | Broadway pipeline. Читает сообщения, декодирует JSON, вызывает отправку. |
| `Notifier.EmailSender` | Формирует `Swoosh.Email` и передаёт в Mailer. |
| `Notifier.Mailer` | Обёртка над `Swoosh.Mailer`, отправка через SMTP. |
| `NotifierWeb` | Заглушка Phoenix-структуры (не используется, оставлена из шаблона). |

## Требования

- **Elixir** ~> 1.15
- **Erlang/OTP** 25+
- Доступ к Kafka-брокерам
- SMTP-аккаунт для отправки писем

## Зависимости

| Пакет | Версия | Назначение |
|-------|--------|------------|
| `broadway_kafka` | `~> 0.4.0` | Consumer Kafka для Broadway |
| `swoosh` | `~> 1.14` | Email-фреймворк |
| `gen_smtp` | `~> 1.2` | SMTP-адаптер для Swoosh |
| `jason` | `~> 1.4` | JSON-кодек |
| `dotenvy` | `~> 0.7` | Загрузка переменных окружения из `.env` |

## Переменные окружения

Все обязательны (читаются в `runtime.exs`):

| Переменная | Описание | Пример |
|------------|----------|--------|
| `SMTP_RELAY` | SMTP-сервер исходящей почты | `smtp.yandex.ru` |
| `SMTP_PORT` | Порт SMTP (по умолчанию `465`) | `465` |
| `SMTP_USERNAME` | Логин для SMTP-аутентификации | `*@yandex.ru` |
| `SMTP_PASSWORD` | Пароль или app-specific пароль | `***` |
| `SMTP_FROM_EMAIL` | Email-адрес отправителя | `*@yandex.ru` |
| `KAFKA_BROKERS` | Список Kafka-брокеров | `ip:port` |
| `KAFKA_TOPIC` | Топик для чтения уведомлений | `notifications` |
| `KAFKA_GROUP_ID` | Consumer Group ID | `notifier-group` |

> **Примечание:** В `runtime.exs` уже настроен Yandex-специфичный SSL/SNI для `smtp.yandex.ru`. При смене релея обновите `sockopts` и `server_name_indication`.

## Локальная конфигурация

Для локальной разработки создайте файл `.env` в корне сервиса (`services/notifier/.env`):

```bash
SMTP_RELAY=smtp.yandex.ru
SMTP_PORT=465
SMTP_USERNAME=your_login@yandex.ru
SMTP_PASSWORD=your_password
SMTP_FROM_EMAIL=your_login@yandex.ru
KAFKA_BROKERS=localhost:9092
KAFKA_TOPIC=notifications
KAFKA_GROUP_ID=notifier-group
```

Переменные подхватываются автоматически (через `dotenvy` при старте приложения).

## Формат сообщения в Kafka

Сервис ожидает JSON в `message.data`:

```json
{
  "to": "user@example.com",
  "subject": "Важное уведомление",
  "body": "Текст письма в plain text"
}
```

Поля `subject` и `body` опциональны, по умолчанию:
- `subject` = `"Уведомление"`
- `body` = `""`

## Запуск

### Локально

```bash
cd services/notifier

# Установить зависимости
mix setup

# Запуск (переменные из .env подтягиваются автоматически)
mix run --no-halt
```

### Через Docker

Переменные окружения прокидываются через `docker-compose` (секция `environment` или внешний `.env`-файл для compose):

```bash
# Сборка
docker-compose -f deployment/docker-compose.build.yml build

# Деплой
docker-compose -f deployment/docker-compose.deploy.yml up -d
```

## Структура репозитория

```
notify-x/
├── deployment/           # Docker Compose для сборки и деплоя
├── services/notifier/    # Исходный код сервиса
│   ├── config/           # Конфигурация (dev, prod, runtime)
│   ├── lib/
│   │   └── notifier/     # Основные модули
│   ├── Dockerfile
│   └── mix.exs
└── README.md
```

## Примечания

- **Тесты:** В проекте отсутствуют тесты — они были сгенерированы шаблоном Phoenix, но удалены, так как сервис достаточно простой. При необходимости в будущем будут добавлены `ExUnit`-тесты для `EmailSender` и `KafkaConsumer`.
- **Phoenix Web:** Модули `NotifierWeb` присутствуют в коде, но не используются в runtime. Это артефакт генерации проекта. Если в будущем понадобится Healthcheck endpoint — можно активировать `Endpoint` в супервизоре.
- **Permanent mode:** В `mix.exs` установлен `start_permanent: Mix.env() == :prod`, поэтому в production-окружении приложение запускается в permanent-режиме OTP.