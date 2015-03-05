require 'helper'
require 'sidekiq/scheduled'
require 'sidekiq/middleware/server/retry_jobs'

class TestRetry < Sidekiq::Test
  describe 'middleware' do
    before do
      @redis = Minitest::Mock.new
      # Ugh, this is terrible.
      Sidekiq.instance_variable_set(:@redis, @redis)

      def @redis.with; yield self; end
    end

    let(:worker) do
      Class.new do
        include ::Sidekiq::Worker
      end
    end

    it 'allows disabling retry' do
      msg = { 'class' => 'Bob', 'args' => [1,2,'foo'], 'retry' => false }
      msg2 = msg.dup
      handler = Sidekiq::Middleware::Server::RetryJobs.new
      assert_raises RuntimeError do
        handler.call(worker, msg2, 'default') do
          raise "kerblammo!"
        end
      end
      assert_equal msg, msg2
    end

    it 'allows a numeric retry' do
      @redis.expect :zadd, 1, ['retry', String, String]
      msg = { 'class' => 'Bob', 'args' => [1,2,'foo'], 'retry' => 2 }
      msg2 = msg.dup
      handler = Sidekiq::Middleware::Server::RetryJobs.new
      assert_raises RuntimeError do
        handler.call(worker, msg2, 'default') do
          raise "kerblammo!"
        end
      end
      msg2.delete('failed_at')
      assert_equal({"class"=>"Bob", "args"=>[1, 2, "foo"], "retry"=>2, "queue"=>"default", "error_message"=>"kerblammo!", "error_class"=>"RuntimeError", "retry_count"=>0}, msg2)
      @redis.verify
    end

    it 'allows a max_retries option in initializer' do
      max_retries = 7
      1.upto(max_retries) do
        @redis.expect :zadd, 1, ['retry', String, String]
      end
      msg = { 'class' => 'Bob', 'args' => [1,2,'foo'], 'retry' => true }
      handler = Sidekiq::Middleware::Server::RetryJobs.new({:max_retries => max_retries})
      1.upto(max_retries + 1) do
        assert_raises RuntimeError do
          handler.call(worker, msg, 'default') do
            raise "kerblammo!"
          end
        end
      end
      @redis.verify
    end

    it 'saves backtraces' do
      @redis.expect :zadd, 1, ['retry', String, String]
      msg = { 'class' => 'Bob', 'args' => [1,2,'foo'], 'retry' => true, 'backtrace' => true }
      handler = Sidekiq::Middleware::Server::RetryJobs.new
      c = nil
      assert_raises RuntimeError do
        handler.call(worker, msg, 'default') do
          c = caller(0); raise "kerblammo!"
        end
      end
      assert msg["error_backtrace"]
      assert_equal c[0], msg["error_backtrace"][0]
      @redis.verify
    end

    it 'saves partial backtraces' do
      @redis.expect :zadd, 1, ['retry', String, String]
      msg = { 'class' => 'Bob', 'args' => [1,2,'foo'], 'retry' => true, 'backtrace' => 3 }
      handler = Sidekiq::Middleware::Server::RetryJobs.new
      c = nil
      assert_raises RuntimeError do
        handler.call(worker, msg, 'default') do
          c = caller(0)[0..3]; raise "kerblammo!"
        end
      end
      assert msg["error_backtrace"]
      assert_equal c, msg["error_backtrace"]
    end

    it 'handles a new failed message' do
      @redis.expect :zadd, 1, ['retry', String, String]
      msg = { 'class' => 'Bob', 'args' => [1,2,'foo'], 'retry' => true }
      handler = Sidekiq::Middleware::Server::RetryJobs.new
      assert_raises RuntimeError do
        handler.call(worker, msg, 'default') do
          raise "kerblammo!"
        end
      end
      assert_equal 'default', msg["queue"]
      assert_equal 'kerblammo!', msg["error_message"]
      assert_equal 'RuntimeError', msg["error_class"]
      assert_equal 0, msg["retry_count"]
      refute msg["error_backtrace"]
      assert msg["failed_at"]
      @redis.verify
    end

    it 'allows a retry queue' do
      @redis.expect :zadd, 1, ['retry', String, String]
      msg = { 'class' => 'Bob', 'args' => [1,2,'foo'], 'retry' => true, 'retry_queue' => 'retry' }
      handler = Sidekiq::Middleware::Server::RetryJobs.new
      assert_raises RuntimeError do
        handler.call(worker, msg, 'default') do
          raise "kerblammo!"
        end
      end
      assert_equal 'retry', msg["queue"]
      assert_equal 'kerblammo!', msg["error_message"]
      assert_equal 'RuntimeError', msg["error_class"]
      assert_equal 0, msg["retry_count"]
      refute msg["error_backtrace"]
      assert msg["failed_at"]
      @redis.verify
    end

    it 'handles a recurring failed message' do
      @redis.expect :zadd, 1, ['retry', String, String]
      now = Time.now.to_f
      msg = {"class"=>"Bob", "args"=>[1, 2, "foo"], 'retry' => true, "queue"=>"default", "error_message"=>"kerblammo!", "error_class"=>"RuntimeError", "failed_at"=>now, "retry_count"=>10}
      handler = Sidekiq::Middleware::Server::RetryJobs.new
      assert_raises RuntimeError do
        handler.call(worker, msg, 'default') do
          raise "kerblammo!"
        end
      end
      assert_equal 'default', msg["queue"]
      assert_equal 'kerblammo!', msg["error_message"]
      assert_equal 'RuntimeError', msg["error_class"]
      assert_equal 11, msg["retry_count"]
      assert msg["failed_at"]
      @redis.verify
    end

    it 'handles a recurring failed message before reaching user-specifed max' do
      @redis.expect :zadd, 1, ['retry', String, String]
      now = Time.now.to_f
      msg = {"class"=>"Bob", "args"=>[1, 2, "foo"], 'retry' => 10, "queue"=>"default", "error_message"=>"kerblammo!", "error_class"=>"RuntimeError", "failed_at"=>now, "retry_count"=>8}
      handler = Sidekiq::Middleware::Server::RetryJobs.new
      assert_raises RuntimeError do
        handler.call(worker, msg, 'default') do
          raise "kerblammo!"
        end
      end
      assert_equal 'default', msg["queue"]
      assert_equal 'kerblammo!', msg["error_message"]
      assert_equal 'RuntimeError', msg["error_class"]
      assert_equal 9, msg["retry_count"]
      assert msg["failed_at"]
      @redis.verify
    end

    it 'throws away old messages after too many retries (using the default)' do
      now = Time.now.to_f
      msg = {"class"=>"Bob", "args"=>[1, 2, "foo"], "queue"=>"default", "error_message"=>"kerblammo!", "error_class"=>"RuntimeError", "failed_at"=>now, "retry"=>true, "retry_count"=>25}
      @redis.expect :zadd, 1, [ 'retry', String, String ]
      handler = Sidekiq::Middleware::Server::RetryJobs.new
      assert_raises RuntimeError do
        handler.call(worker, msg, 'default') do
          raise "kerblammo!"
        end
      end
      # Minitest can't assert that a method call did NOT happen!?
      assert_raises(MockExpectationError) { @redis.verify }
    end

    it 'throws away old messages after too many retries (using user-specified max)' do
      now = Time.now.to_f
      msg = {"class"=>"Bob", "args"=>[1, 2, "foo"], "queue"=>"default", "error_message"=>"kerblammo!", "error_class"=>"RuntimeError", "failed_at"=>now, "retry"=>3, "retry_count"=>3}
      @redis.expect :zadd, 1, [ 'retry', String, String ]
      handler = Sidekiq::Middleware::Server::RetryJobs.new
      assert_raises RuntimeError do
        handler.call(worker, msg, 'default') do
          raise "kerblammo!"
        end
      end
      # Minitest can't assert that a method call did NOT happen!?
      assert_raises(MockExpectationError) { @redis.verify }
    end

    describe "retry exhaustion" do
      let(:handler){ Sidekiq::Middleware::Server::RetryJobs.new }
      let(:worker) { Minitest::Mock.new }
      let(:msg){ {"class"=>"Bob", "args"=>[1, 2, "foo"], "queue"=>"default", "error_message"=>"kerblammo!", "error_class"=>"RuntimeError", "failed_at"=>Time.now.to_f, "retry"=>3, "retry_count"=>3} }

      describe "worker method" do
        let(:worker) do
          klass = Class.new do
            include Sidekiq::Worker

            def self.name; "Worker"; end

            def retries_exhausted(*args)
              args << "retried_method"
            end
          end
        end

        it 'calls worker.retries_exhausted after too many retries' do
          assert_equal [1,2, "foo", "retried_method"], handler.__send__(:retries_exhausted, worker.new, msg)
        end
      end

      describe "worker block" do
        let(:worker) do
          Class.new do
            include Sidekiq::Worker

            sidekiq_retries_exhausted do |msg|
              msg.tap {|m| m['called_by_callback'] = true }
            end
          end
        end

        it 'calls worker sidekiq_retries_exhausted_block after too many retries' do
          new_msg      = handler.__send__(:retries_exhausted, worker.new, msg)
          expected_msg = msg.merge('called_by_callback' => true)

          assert_equal expected_msg, new_msg, "sidekiq_retries_exhausted block not called"
        end
      end

      it 'handles and logs retries_exhausted failures gracefully (drops them)' do
        def worker.retries_exhausted(*args)
          raise 'bam!'
        end

        e = task_misbehaving_worker
        assert_equal e.message, "kerblammo!"
        worker.verify
      end

      def task_misbehaving_worker
        assert_raises RuntimeError do
          handler.call(worker, msg, 'default') do
            raise 'kerblammo!'
          end
        end
      end
    end

    describe "custom retry delay" do
      before do
        @old_logger    = Sidekiq.logger
        @tmp_log_path  = '/tmp/sidekiq-retries.log'
        Sidekiq.logger = Logger.new(@tmp_log_path)
      end

      after do
        Sidekiq.logger = @old_logger
        Sidekiq.options.delete(:logfile)
        File.unlink @tmp_log_path if File.exists?(@tmp_log_path)
      end

      let(:custom_worker) do
        Class.new do
          include ::Sidekiq::Worker

          sidekiq_retry_in do |count|
            count * 2
          end
        end
      end

      let(:error_worker) do
        Class.new do
          include ::Sidekiq::Worker

          sidekiq_retry_in do |count|
            count / 0
          end
        end
      end

      let(:handler) { Sidekiq::Middleware::Server::RetryJobs.new }

      it "retries with a default delay" do
        refute_equal 4, handler.__send__(:delay_for, worker, 2)
      end

      it "retries with a custom delay" do
        assert_equal 4, handler.__send__(:delay_for, custom_worker, 2)
      end

      it "falls back to the default retry on exception" do
        refute_equal 4, handler.__send__(:delay_for, error_worker, 2)
        assert_match(/Failure scheduling retry using the defined `sidekiq_retry_in`/,
                     File.read(@tmp_log_path), 'Log entry missing for sidekiq_retry_in')
      end
    end
  end

end
