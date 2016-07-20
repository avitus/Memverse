FROM alpine:3.4

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
					nodejs \ 
					tzdata

ENV RUBY_PACKAGES	ruby ruby-io-console ruby-bundler ruby-irb ruby-json ruby-bigdecimal

ENV MYSQL_PACKAGES	mysql-client mysql-dev

ENV SQLITE_PACKAGES	sqlite-libs sqlite-dev

# ENTRYPOINT ["mysql"]

# === Install Packages================================================================
#
# update: 	get latest list of packages
# upgrade:	upgrade all packages of running system
# add:		--no-cache flag will remove cache
#
# ====================================================================================
RUN apk update && \
    apk upgrade && \
    apk --update add $MYSQL_PACKAGES && \
    apk --update add $SQLITE_PACKAGES && \
    apk --update add $BUILD_PACKAGES && \
    apk --update add $RUBY_PACKAGES && \ 
    rm -rf /var/cache/apk/*     

ENV RAILS_ENV development
ENV APP_HOME /usr/app
RUN mkdir -p $APP_HOME
WORKDIR $APP_HOME

COPY Gemfile /usr/app/
COPY Gemfile.lock /usr/app/

# Install gems in vendor/cache ( this is specified in .bundle/config )
RUN bundle install && \ 
    rm -rf /var/cache/apk/*     

COPY . /usr/app

EXPOSE 3000

# The main command to run when the container starts. Also 
# tell the Rails dev server to bind to all interfaces by 
# default.
CMD ["bundle", "exec", "rails", "server", "-e", "development", "-b", "0.0.0.0"]