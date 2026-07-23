FROM elixir:1.17-alpine

RUN apk add --no-cache build-base git cmake ca-certificates
RUN update-ca-certificates

WORKDIR /app

COPY mix.exs mix.lock ./
RUN mix local.hex --force && mix local.rebar --force
RUN mix deps.get
RUN mix deps.compile

COPY . .
RUN mix compile

CMD ["mix", "run", "--no-halt"]