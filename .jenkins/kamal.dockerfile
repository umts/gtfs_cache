ARG RUBY_VERSION
FROM ruby:${RUBY_VERSION}

RUN apt-get update && \
    apt-get install -y docker.io openssh-client && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives
