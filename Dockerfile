FROM hexpm/elixir:1.19.1-erlang-28.0-debian-bullseye-20251117

RUN apt-get update && apt-get install -y --no-install-recommends \
  build-essential \
  git \
  curl \
  postgresql-client \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN mix local.hex --force && mix local.rebar --force

COPY mix.exs mix.lock ./
COPY config config

RUN mix deps.get

COPY . .
RUN chmod +x docker/start-web.sh bin/dev-up bin/dev-down

EXPOSE 4010

CMD ["sh", "/app/docker/start-web.sh"]
