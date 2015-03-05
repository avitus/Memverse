# encoding: utf-8
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/rpm/blob/master/LICENSE for complete details.

module NewRelic
  module Agent
    class Harvester

      attr_accessor :starting_pid

      # Inject target for after_fork call to avoid spawning thread in tests
      def initialize(events, after_forker=NewRelic::Agent)
        # We intentionally don't set our pid as started at this point.
        # Startup routines must call mark_started when they consider us set!
        @starting_pid = nil

        @after_forker = after_forker
        @lock = Mutex.new

        if events
          events.subscribe(:start_transaction, &method(:on_transaction))
        end
      end

      def on_transaction(*_)
        return unless restart_in_children_enabled? && needs_restart?

        needs_thread_start = false
        @lock.synchronize do
          needs_thread_start = needs_restart?
          mark_started
        end

        if needs_thread_start
          restart_harvest_thread
        end
      end

      def mark_started(pid = Process.pid)
        @starting_pid = pid
      end

      def needs_restart?(pid = Process.pid)
        @starting_pid != pid
      end

      def restart_in_children_enabled?
        NewRelic::Agent.config[:restart_thread_in_children]
      end

      def restart_harvest_thread
        # Daemonize reports thread as still alive when it isn't... whack!
        NewRelic::Agent.instance.instance_variable_set(:@worker_thread, nil)
        @after_forker.after_fork(:force_reconnect => true)
      end

    end
  end
end
