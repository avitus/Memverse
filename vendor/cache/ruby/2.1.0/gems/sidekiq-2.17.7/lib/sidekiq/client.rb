require 'securerandom'
require 'sidekiq/middleware/chain'

module Sidekiq
  class Client

    ##
    # Define client-side middleware:
    #
    #   client = Sidekiq::Client.new
    #   client.middleware do |chain|
    #     chain.use MyClientMiddleware
    #   end
    #   client.push('class' => 'SomeWorker', 'args' => [1,2,3])
    #
    # All client instances default to the globally-defined
    # Sidekiq.client_middleware but you can change as necessary.
    #
    def middleware(&block)
      @chain ||= Sidekiq.client_middleware
      if block_given?
        @chain = @chain.dup
        yield @chain
      end
      @chain
    end

    ##
    # The main method used to push a job to Redis.  Accepts a number of options:
    #
    #   queue - the named queue to use, default 'default'
    #   class - the worker class to call, required
    #   args - an array of simple arguments to the perform method, must be JSON-serializable
    #   retry - whether to retry this job if it fails, true or false, default true
    #   backtrace - whether to save any error backtrace, default false
    #
    # All options must be strings, not symbols.  NB: because we are serializing to JSON, all
    # symbols in 'args' will be converted to strings.
    #
    # Returns nil if not pushed to Redis or a unique Job ID if pushed.
    #
    # Example:
    #   push('queue' => 'my_queue', 'class' => MyWorker, 'args' => ['foo', 1, :bat => 'bar'])
    #
    def push(item)
      normed = normalize_item(item)
      payload = process_single(item['class'], normed)

      pushed = false
      pushed = raw_push([payload]) if payload
      pushed ? payload['jid'] : nil
    end

    ##
    # Push a large number of jobs to Redis.  In practice this method is only
    # useful if you are pushing tens of thousands of jobs or more, or if you need
    # to ensure that a batch doesn't complete prematurely.  This method
    # basically cuts down on the redis round trip latency.
    #
    # Takes the same arguments as #push except that args is expected to be
    # an Array of Arrays.  All other keys are duplicated for each job.  Each job
    # is run through the client middleware pipeline and each job gets its own Job ID
    # as normal.
    #
    # Returns an array of the of pushed jobs' jids or nil if the pushed failed.  The number of jobs
    # pushed can be less than the number given if the middleware stopped processing for one
    # or more jobs.
    def push_bulk(items)
      normed = normalize_item(items)
      payloads = items['args'].map do |args|
        raise ArgumentError, "Bulk arguments must be an Array of Arrays: [[1], [2]]" if !args.is_a?(Array)
        process_single(items['class'], normed.merge('args' => args, 'jid' => SecureRandom.hex(12), 'enqueued_at' => Time.now.to_f))
      end.compact

      pushed = false
      pushed = raw_push(payloads) if !payloads.empty?
      pushed ? payloads.collect { |payload| payload['jid'] } : nil
    end

    class << self
      def default
        @default ||= new
      end

      # deprecated
      def registered_workers
        puts "registered_workers is deprecated, please use Sidekiq::Workers.new"
        Sidekiq.redis { |x| x.smembers('workers') }
      end

      # deprecated
      def registered_queues
        puts "registered_queues is deprecated, please use Sidekiq::Queue.all"
        Sidekiq::Queue.all.map(&:name)
      end

      def push(item)
        default.push(item)
      end

      def push_bulk(items)
        default.push_bulk(items)
      end

      # Resque compatibility helpers.  Note all helpers
      # should go through Worker#client_push.
      #
      # Example usage:
      #   Sidekiq::Client.enqueue(MyWorker, 'foo', 1, :bat => 'bar')
      #
      # Messages are enqueued to the 'default' queue.
      #
      def enqueue(klass, *args)
        klass.client_push('class' => klass, 'args' => args)
      end

      # Example usage:
      #   Sidekiq::Client.enqueue_to(:queue_name, MyWorker, 'foo', 1, :bat => 'bar')
      #
      def enqueue_to(queue, klass, *args)
        klass.client_push('queue' => queue, 'class' => klass, 'args' => args)
      end

      # Example usage:
      #   Sidekiq::Client.enqueue_to_in(:queue_name, 3.minutes, MyWorker, 'foo', 1, :bat => 'bar')
      #
      def enqueue_to_in(queue, interval, klass, *args)
        int = interval.to_f
        now = Time.now.to_f
        ts = (int < 1_000_000_000 ? now + int : int)

        item = { 'class' => klass, 'args' => args, 'at' => ts, 'queue' => queue }
        item.delete('at') if ts <= now

        klass.client_push(item)
      end

      # Example usage:
      #   Sidekiq::Client.enqueue_in(3.minutes, MyWorker, 'foo', 1, :bat => 'bar')
      #
      def enqueue_in(interval, klass, *args)
        klass.perform_in(interval, *args)
      end
    end

    private

    def raw_push(payloads)
      pushed = false
      Sidekiq.redis do |conn|
        if payloads.first['at']
          pushed = conn.zadd('schedule', payloads.map do |hash|
            at = hash.delete('at').to_s
            [at, Sidekiq.dump_json(hash)]
          end)
        else
          q = payloads.first['queue']
          to_push = payloads.map { |entry| Sidekiq.dump_json(entry) }
          _, pushed = conn.multi do
            conn.sadd('queues', q)
            conn.lpush("queue:#{q}", to_push)
          end
        end
      end
      pushed
    end

    def process_single(worker_class, item)
      queue = item['queue']

      middleware.invoke(worker_class, item, queue) do
        item
      end
    end

    def normalize_item(item)
      raise(ArgumentError, "Message must be a Hash of the form: { 'class' => SomeWorker, 'args' => ['bob', 1, :foo => 'bar'] }") unless item.is_a?(Hash)
      raise(ArgumentError, "Message must include a class and set of arguments: #{item.inspect}") if !item['class'] || !item['args']
      raise(ArgumentError, "Message args must be an Array") unless item['args'].is_a?(Array)
      raise(ArgumentError, "Message class must be either a Class or String representation of the class name") unless item['class'].is_a?(Class) || item['class'].is_a?(String)

      if item['class'].is_a?(Class)
        raise(ArgumentError, "Message must include a Sidekiq::Worker class, not class name: #{item['class'].ancestors.inspect}") if !item['class'].respond_to?('get_sidekiq_options')
        normalized_item = item['class'].get_sidekiq_options.merge(item)
        normalized_item['class'] = normalized_item['class'].to_s
      else
        normalized_item = Sidekiq.default_worker_options.merge(item)
      end

      normalized_item['queue'] = normalized_item['queue'].to_s
      normalized_item['jid'] ||= SecureRandom.hex(12)
      normalized_item['enqueued_at'] ||= Time.now.to_f
      normalized_item
    end

  end
end
