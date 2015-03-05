Dalli [![Build Status](https://secure.travis-ci.org/mperham/dalli.png)](http://travis-ci.org/mperham/dalli) [![Dependency Status](https://gemnasium.com/mperham/dalli.png)](https://gemnasium.com/mperham/dalli) [![Code Climate](https://codeclimate.com/github/mperham/dalli.png)](https://codeclimate.com/github/mperham/dalli)
=====

Dalli is a high performance pure Ruby client for accessing memcached servers.  It works with memcached 1.4+ only as it uses the newer binary protocol.  It should be considered a replacement for the memcache-client gem.

The name is a variant of Salvador Dali for his famous painting [The Persistence of Memory](http://en.wikipedia.org/wiki/The_Persistence_of_Memory).

![Persistence of Memory](http://www.virtualdali.com/assets/paintings/31PersistenceOfMemory.jpg)

Dalli's initial development was sponsored by [CouchBase](http://www.couchbase.com/).  Many thanks to them!


Design
------------

I decided to write Dalli after maintaining memcache-client for two years for a few specific reasons:

 0. The code is mostly old and gross.  The bulk of the code is a single 1000 line .rb file.
 1. It has a lot of options that are infrequently used which complicate the codebase.
 2. The implementation has no single point to attach monitoring hooks.
 3. Uses the old text protocol, which hurts raw performance.

So a few notes.  Dalli:

 0. uses the exact same algorithm to choose a server so existing memcached clusters with TBs of data will work identically to memcache-client.
 1. is approximately 20% faster than memcache-client (which itself was heavily optimized) in Ruby 1.9.2.
 2. contains explicit "chokepoint" methods which handle all requests; these can be hooked into by monitoring tools (NewRelic, Rack::Bug, etc) to track memcached usage.
 3. supports SASL for use in managed environments, e.g. Heroku.
 4. provides proper failover with recovery and adjustable timeouts


Supported Ruby versions and implementations
------------------------------------------------

Dalli should work identically on:

 * JRuby 1.6+
 * Ruby 1.9.3+
 * Rubinius 2.0

If you have problems, please enter an issue.


Installation and Usage
------------------------

Remember, Dalli **requires** memcached 1.4+. You can check the version with `memcached -h`. Please note that memcached that Mac OS X Snow Leopard ships with is 1.2.8 and won't work. Install 1.4.x using Homebrew with

    brew install memcached

On Ubuntu you can install it by running:

    apt-get install memcached

You can verify your installation using this piece of code:

```bash
gem install dalli
```

```ruby
require 'dalli'
options = { :namespace => "app_v1", :compress => true }
dc = Dalli::Client.new('localhost:11211', options)
dc.set('abc', 123)
value = dc.get('abc')
```

The test suite requires memcached 1.4.3+ with SASL enabled (brew install memcached --enable-sasl ; mv /usr/bin/memcached /usr/bin/memcached.old).  Currently only supports the PLAIN mechanism.

Dalli has no runtime dependencies and never will.  You can optionally install the 'kgio' gem to
give Dalli a 20-30% performance boost.


Usage with Rails 3.x and 4.x
---------------------------

In your Gemfile:

```ruby
gem 'dalli'
```

In `config/environments/production.rb`:

```ruby
config.cache_store = :dalli_store
```

Here's a more comprehensive example that sets a reasonable default for maximum cache entry lifetime (one day), enables compression for large values and namespaces all entries for this rails app.  Remove the namespace if you have multiple apps which share cached values.

```ruby
config.cache_store = :dalli_store, 'cache-1.example.com', 'cache-2.example.com',
  { :namespace => NAME_OF_RAILS_APP, :expires_in => 1.day, :compress => true }
```

To use Dalli for Rails session storage that times out after 20 minutes, in `config/initializers/session_store.rb`:

For Rails >= 3.2.4:

```ruby
Rails.application.config.session_store ActionDispatch::Session::CacheStore, :expire_after => 20.minutes
```

For Rails 3.x:

```ruby
require 'action_dispatch/middleware/session/dalli_store'
Rails.application.config.session_store :dalli_store, :memcache_server => ['host1', 'host2'], :namespace => 'sessions', :key => '_foundation_session', :expire_after => 20.minutes
```

Dalli does not support Rails 2.x.


Multithreading and Rails
--------------------------

If you use Puma or another threaded app server, as of Dalli 2.7, you can use a pool
of Dalli clients with Rails to ensure the `Rails.cache` singleton does not become a
source of thread contention.  You must add `gem 'connection_pool'` to your Gemfile and
add :pool\_size to your `dalli_store` config:

```ruby
config.cache_store = :dalli_store, 'cache-1.example.com', { :pool_size => 5 }
```


Configuration
------------------------

Dalli::Client accepts the following options. All times are in seconds.

**expires_in**: Global default for key TTL.  Default is 0, which means no expiry.

**failover**: Boolean, if true Dalli will failover to another server if the main server for a key is down.

**compress**: Boolean, if true Dalli will gzip-compress values larger than 1K.

**compression_min_size**: Minimum value byte size for which to attempt compression. Default is 1K.

**compression_max_size**: Maximum value byte size for which to attempt compression. Default is unlimited.

**serializer**: The serializer to use for objects being stored (ex. JSON).
Default is Marshal.

**socket_timeout**: Timeout for all socket operations (connect, read, write). Default is 0.5.

**socket_max_failures**: When a socket operation fails after socket_timeout, the same operation is retried. This is to not immediately mark a server down when there's a very slight network problem. Default is 2.

**socket_failure_delay**: Before retrying a socket operation, the process sleeps for this amount of time. Default is 0.01.  Set to nil for no delay.

**down_retry_delay**: When a server has been marked down due to many failures, the server will be checked again for being alive only after this amount of time. Don't set this value to low, otherwise each request which tries the failed server might hang for the maximum **socket_timeout**. Default is 1 second.

**value_max_bytes**: The maximum size of a value in memcached.  Defaults to 1MB, this can be increased with memcached's -I parameter.  You must also configure Dalli to allow the larger size here.

**username**: The username to use for authenticating this client instance against a SASL-enabled memcached server.  Heroku users should not need to use this normally.

**password**: The password to use for authenticating this client instance against a SASL-enabled memcached server.  Heroku users should not need to use this normally.

**keepalive**: Boolean. If true, Dalli will enable keep-alive for socket connections.  Default is true.

**compressor**: The compressor to use for objects being stored.
Default is zlib, implemented under `Dalli::Compressor`.
If serving compressed data using nginx's HttpMemcachedModule, set `memcached_gzip_flag 2` and use `Dalli::GzipCompressor`

Features and Changes
------------------------

By default, Dalli is thread-safe.  Disable thread-safety at your own peril.

Dalli does not need anything special in Unicorn/Passenger since 2.0.4.
It will detect sockets shared with child processes and gracefully reopen the
socket.

Note that Dalli does not require ActiveSupport or Rails.  You can safely use it in your own Ruby projects.

[View the Client API](http://www.rubydoc.info/github/mperham/dalli/Dalli/Client)

Helping Out
-------------

If you have a fix you wish to provide, please fork the code, fix in your local project and then send a pull request on github.  Please ensure that you include a test which verifies your fix and update History.md with a one sentence description of your fix so you get credit as a contributor.

We're not accepting new compressors. They are trivial to add in an initializer. See #385 (LZ4), #406 (Snappy)

Thanks
------------

Eric Wong - for help using his [kgio](http://unicorn.bogomips.org/kgio/index.html) library.

Brian Mitchell - for his remix-stash project which was helpful when implementing and testing the binary protocol support.

[CouchBase](http://couchbase.com) - for their project sponsorship


Author
----------

Mike Perham, [mikeperham.com](http://mikeperham.com), [@mperham](http://twitter.com/mperham)


Copyright
-----------

Copyright (c) Mike Perham. See LICENSE for details.
