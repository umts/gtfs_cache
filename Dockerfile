# syntax=docker/dockerfile:1
# check=error=true

# This Dockerfile is designed for production, not development. Use with Kamal or build'n'run by hand:
# docker build --tag gtfs_cache --build-arg RUBY_VERSION="$(cat .ruby-version)" .
# docker run --interactive --tty --publish 80:80 --env MASTER_KEY="$(cat config/gtfs_cache.key)" gtfs_cache

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
ARG RUBY_VERSION=OVERRIDE_ME
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

# App lives here
WORKDIR /app

# Install base packages
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y libjemalloc2 && \
    ln -s /usr/lib/$(uname -m)-linux-gnu/libjemalloc.so.2 /usr/local/lib/libjemalloc.so && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Set production environment variables and enable jemalloc for reduced memory usage and latency
ENV RACK_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_ONLY="default production" \
    LD_PRELOAD="/usr/local/lib/libjemalloc.so"


# Throw-away build stage to reduce size of final image
FROM base AS build

# Install packages needed to build gems
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install application gems
COPY .ruby-version Gemfile Gemfile.lock ./

RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git


# Final stage for app image
FROM base

# Copy built artifacts: gems, application
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"

# Copy application code
COPY . .

# Run and own only the runtime files as a non-root user for security
RUN groupadd --system --gid 1000 gtfs-cache && \
    useradd gtfs-cache --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    mkdir -p /app/log /app/tmp && chown -R gtfs-cache:gtfs-cache /app/log /app/tmp
USER 1000:1000

EXPOSE 80
CMD ["script/server", "--port=80"]
