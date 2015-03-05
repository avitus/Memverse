# Run with `sidekiq -r /path/to/simple.rb`

require 'sidekiq'
require 'sidetiq'
require 'sidetiq/lock/watcher'

require_relative 'workers/simple'
require_relative 'workers/failing'

Sidekiq.logger.level = Logger::DEBUG

Sidekiq.options[:poll_interval] = 1

