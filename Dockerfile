# Use phusion/passenger-full as base image. To make your builds reproducible, make
# sure you lock down to a specific version, not to `latest`!
# See https://github.com/phusion/passenger-docker/blob/master/Changelog.md for
# a list of version numbers.
# FROM phusion/passenger-full:0.9.18

FROM alpine:3.3

MAINTAINER Memverse "admin@memverse.com"

# === Dependencies ==================================================
# Eventmachine	mysql2		g++ musl-dev make
# nokogiri 					libxml2-dev and libxslt-dev
# ffi						libffi-dev
# ===================================================================
ENV BUILD_PACKAGES	bash git curl-dev git-perl ruby-dev build-base openssl-dev \
					libxml2-dev libxslt-dev libffi-dev \
					g++ musl-dev make
ENV RUBY_PACKAGES	ruby ruby-io-console ruby-bundler ruby-irb ruby-json

RUN apk add --no-cache mysql-client mysql-dev sqlite-libs sqlite-dev
ENTRYPOINT ["mysql"]

# Update and install all of the required packages. At the end, remove the apk cache
RUN apk update && \
    apk upgrade && \
    apk --update add $BUILD_PACKAGES && \
    apk --update add $RUBY_PACKAGES && \
    rm -rf /var/cache/apk/*

RUN mkdir /usr/app
WORKDIR /usr/app

COPY Gemfile /usr/app/
COPY Gemfile.lock /usr/app/

# Install gems in vendor/cache ( this is specified in .bundle/config )
RUN bundle config build.nokogiri --use-system-libraries && \
    bundle install --path vendor/cache

COPY . /usr/app

CMD ["bundle", "exec", "unicorn", "-p", "8080", "-c", "./config/unicorn.rb"]