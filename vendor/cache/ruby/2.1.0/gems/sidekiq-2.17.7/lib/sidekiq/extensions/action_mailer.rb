require 'sidekiq/extensions/generic_proxy'

module Sidekiq
  module Extensions
    ##
    # Adds 'delay', 'delay_for' and `delay_until` methods to ActionMailer to offload arbitrary email
    # delivery to Sidekiq.  Example:
    #
    #    UserMailer.delay.send_welcome_email(new_user)
    #    UserMailer.delay_for(5.days).send_welcome_email(new_user)
    #    UserMailer.delay_until(5.days.from_now).send_welcome_email(new_user)
    class DelayedMailer
      include Sidekiq::Worker

      def perform(yml)
        (target, method_name, args) = YAML.load(yml)
        msg = target.__send__(method_name, *args)
        # The email method can return nil, which causes ActionMailer to return
        # an undeliverable empty message.
        msg.deliver if msg && (msg.to || msg.cc || msg.bcc) && msg.from
      end
    end

    module ActionMailer
      def sidekiq_delay(options={})
        Proxy.new(DelayedMailer, self, options)
      end
      def sidekiq_delay_for(interval, options={})
        Proxy.new(DelayedMailer, self, options.merge('at' => Time.now.to_f + interval.to_f))
      end
      def sidekiq_delay_until(timestamp, options={})
        Proxy.new(DelayedMailer, self, options.merge('at' => timestamp.to_f))
      end
      alias_method :delay, :sidekiq_delay
      alias_method :delay_for, :sidekiq_delay_for
      alias_method :delay_until, :sidekiq_delay_until
    end

  end
end
