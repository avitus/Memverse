# Use phusion/passenger-full as base image. To make your builds reproducible, make
# sure you lock down to a specific version, not to `latest`!
# See https://github.com/phusion/passenger-docker/blob/master/Changelog.md for
# a list of version numbers.
# FROM phusion/passenger-full:<0.9.18>

FROM alpine:3.3

MAINTAINER Memverse "admin@memverse.com"

RUN apk add --no-cache mysql-client
ENTRYPOINT ["mysql"]

RUN apk update && apk --update add \
	bash \
	ruby \
	ruby-irb \
	ruby-json \ 
	ruby-rake \  
    ruby-bigdecimal \
    ruby-io-console \
    libstdc++ tzdata \
    nodejs


# Set correct environment variables.
# ENV HOME /root

ADD Gemfile ./Gemfile
ADD Gemfile.lock ./Gemfile.lock 

RUN apk --update add --virtual \
	build-dependencies \
	build-base \
	ruby-dev \
	openssl-dev \  
    libc-dev \
    linux-headers && \
    gem install bundler && \
    cd /app ; bundle install --without development test && \
    apk del build-dependencies

ADD . /app  
RUN chown -R nobody:nogroup /app  
USER nobody

ENV RAILS_ENV production  
WORKDIR /app

CMD ["bundle", "exec", "unicorn", "-p", "8080", "-c", "./config/unicorn.rb"]