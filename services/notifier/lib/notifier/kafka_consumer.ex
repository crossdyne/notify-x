defmodule Notifier.KafkaConsumer do
  use Broadway

  def start_link(_opts) do
    config = Application.get_env(:notifier, __MODULE__)

    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module: {BroadwayKafka.Producer, [
          hosts: config[:brokers],
          group_id: config[:group_id],
          topics: [config[:topic]]
        ]}
      ],
      processors: [
        default: [concurrency: 2]
      ]
    )
  end

  @impl true
  def handle_message(_processor, message, _context) do
    case Jason.decode(message.data) do
      {:ok, payload} ->
        to = payload["to"]
        subject = payload["subject"] || "Уведомление"
        body = payload["body"] || ""

        case Notifier.EmailSender.send(to, subject, body) do
          {:ok, _response} ->
            IO.puts("Письмо успешно отправлено на #{to}")
            message

          {:error, reason} ->
            IO.puts("Ошибка отправки: #{inspect(reason)}")
            message
        end

      {:error, _} ->
        IO.puts("Ошибка парсинга JSON: #{inspect(message.data)}")
        message
    end
  end
end
