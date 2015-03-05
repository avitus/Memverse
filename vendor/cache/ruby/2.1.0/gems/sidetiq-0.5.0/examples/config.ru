require 'sidekiq'
require 'sidetiq'

require 'sidekiq/web'
require 'sidetiq/web'
require 'sidetiq/lock/watcher'

require './workers/simple.rb'
require './workers/failing.rb'

Sidekiq.configure_client do |config|
  config.redis = { :size => 1 }
end

run Sidekiq::Web
