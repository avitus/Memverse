module Sidetiq
  module Actor
    class Clock < Sidetiq::Clock
      include Sidetiq::Actor
      include Sidekiq::ExceptionHandler

      def initialize(*args, &block)
        super

        if Sidekiq.server?
          after(0) do
            debug "Sidetiq::Clock looping ..."
            loop!
          end
        end
      end

      private

      def loop!
        after([time { tick }, 0].max) do
          loop!
        end
      rescue StandardError => e
        handle_exception(e, context: 'Sidetiq::Clock#loop!')
        raise e
      end

      def time
        start = gettime
        yield
        Sidetiq.config.resolution - (gettime.to_f - start.to_f)
      end
    end
  end
end
