# Stage 1: Build
FROM docker.io/library/elixir:1.18.4-alpine AS builder
WORKDIR /app
RUN apk add --no-cache build-base git curl postgresql-client
COPY mix.exs mix.lock ./
COPY config ./config
ENV MIX_ENV=prod
RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get --only prod

COPY lib ./lib
COPY priv ./priv
COPY assets ./assets

# Compile for PROD

RUN mix compile
RUN mix assets.deploy
RUN mix release

# Stage 2: Runtime
FROM docker.io/library/elixir:1.18.4-alpine AS runtime

RUN apk add --no-cache postgresql-client libstdc++ openssl ncurses-libs
WORKDIR /app

COPY --from=builder /app/_build/prod/rel /app/rel

ENV MIX_ENV=prod PORT=4000
ENV HOME=/app
ENV SHELL=/bin/sh
EXPOSE 4000

CMD ["/app/rel/routine/bin/routine", "start"]
