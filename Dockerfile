# Use phusion/passenger-full as base image. To make your builds reproducible, make
# sure you lock down to a specific version, not to `latest`!
# See https://github.com/phusion/passenger-docker/blob/master/Changelog.md for
# a list of version numbers.
# FROM phusion/passenger-full:0.9.18

FROM alpine:3.3

MAINTAINER Memverse "admin@memverse.com"

# === Dependencies ===================================================================
#
# Gem           RequiredBy  Alpine Libraries 
# ~~~~~~~~~~~~  ~~~~~~~~~~  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Eventmachine	[mysql2]	g++ musl-dev make
# nokogiri 		[rails]		libxml2-dev and libxslt-dev
# ffi						libffi-dev
#
# To check on a gem dependency use 
#      gem dependency nokogiri --reverse-dependencies
#
# ====================================================================================

ENV BUILD_PACKAGES	bash git curl-dev git-perl ruby-dev build-base openssl-dev \
					libxml2-dev libxslt-dev libffi-dev \
					g++ musl-dev make \ 
					nodejs
ENV RUBY_PACKAGES	ruby ruby-io-console ruby-bundler ruby-irb ruby-json ruby-bigdecimal

RUN apk add --no-cache mysql-client mysql-dev sqlite-libs sqlite-dev

# ENTRYPOINT ["mysql"]

# Update and install all of the required packages. At the end, remove the apk cache
RUN apk update && \
    apk upgrade && \
    apk --update add $BUILD_PACKAGES && \
    apk --update add $RUBY_PACKAGES 
#   rm -rf /var/cache/apk/*     <-- Don't remove packages for now.

RUN mkdir /usr/app
WORKDIR /usr/app

COPY Gemfile /usr/app/
COPY Gemfile.lock /usr/app/

# Install gems in vendor/cache ( this is specified in .bundle/config )
RUN bundle config build.nokogiri --use-system-libraries && \
    bundle install --path vendor/cache

COPY . /usr/app

EXPOSE 3000

# The main command to run when the container starts. Also 
# tell the Rails dev server to bind to all interfaces by 
# default.
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]