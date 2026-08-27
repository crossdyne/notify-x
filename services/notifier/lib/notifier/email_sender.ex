defmodule Notifier.EmailSender do
  alias Swoosh.Email
  import Swoosh.Email

  def send(to, subject, body) do
    from_email = Application.get_env(:notifier, :from_email, "crossdyne@yandex.ru")

    Email.new()
    |> to(to)
    |> from({"Сервис уведомлений", from_email})
    |> subject(subject)
    |> text_body(body)
    |> Notifier.Mailer.deliver()
  end
end
