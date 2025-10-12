FROM docker.io/library/elixir:1.18.4-alpine
WORKDIR /app
RUN apk update && \
    apk add --no-cache inotify-tools git curl build-base postgresql-client
COPY mix.exs mix.lock ./
COPY config ./config
COPY lib ./lib
COPY priv ./priv
COPY test ./test
COPY run /app/run
RUN chmod +x /app/run
RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get
RUN mix compile
EXPOSE 4000
CMD ["./run"]
