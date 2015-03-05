Sidetiq.logger.warn "Sidetiq::Lock::Watcher is experimental and the behavior and API may change in a future version."

module Sidetiq
  configure do |config|
    config.lock = OpenStruct.new.tap do |lock|
      lock.watcher = OpenStruct.new.tap do |watcher|
        watcher.remove_lock = false
        watcher.notify = true
      end
    end
  end

  module Lock
    class Watcher
      class StaleLogError < StandardError; end

      include Sidekiq::Worker
      include Sidekiq::ExceptionHandler
      include Sidetiq::Schedulable

      recurrence do
        minutely.second_of_minute(0, 10, 20, 30, 40, 50)
      end

      def perform
        Sidetiq::Lock::Redis.all.each do |lock|
          next unless lock.stale?

          if Sidetiq.config.lock.watcher.remove_lock
            lock.unlock!
          end

          if Sidetiq.config.lock.watcher.notify
            ex = StaleLogError.new("Stale lock detected: #{lock.key} (#{lock.meta_data})")
            handle_exception(ex, context: "Sidetiq::Lock::Watcher#perform")
          end
        end
      end
    end
  end
end
