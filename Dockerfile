ARG RUBY_VERSION=OVERRIDE_ME

FROM registry.docker.com/library/ruby:$RUBY_VERSION-slim AS base

LABEL org.opencontainers.image.source=https://github.com/umts/gtfs_cache
LABEL org.opencontainers.image.description="gtfs_cache"
LABEL org.opencontainers.image.licenses=MIT

ENV RACK_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_ONLY="default production" \
    BUNDLE_PATH="/usr/local/bundle"

WORKDIR /app

FROM base AS build

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential libssl-dev

COPY .ruby-version Gemfile Gemfile.lock ./

RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

FROM base

RUN apt-get update -qq && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

COPY --from=build /usr/local/bundle /usr/local/bundle

COPY . .

RUN useradd gtfs-cache --create-home --shell /bin/bash && \
    mkdir -p log tmp && \
    chown -R gtfs-cache log tmp

USER gtfs-cache:gtfs-cache

EXPOSE 80

CMD ["script/server", "--port=80"]
