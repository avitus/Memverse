require 'helper'
require 'sidekiq/scheduled'

class TestScheduling < Sidekiq::Test
  describe 'middleware' do
    before do
      @redis = Minitest::Mock.new
      # Ugh, this is terrible.
      Sidekiq.instance_variable_set(:@redis, @redis)
      def @redis.multi; [yield] * 2 if block_given?; end
      def @redis.with; yield self; end
    end

    class ScheduledWorker
      include Sidekiq::Worker
      sidekiq_options :queue => :custom_queue
      def perform(x)
      end
    end

    it 'schedules a job via interval' do
      @redis.expect :zadd, true, ['schedule', Array]
      assert ScheduledWorker.perform_in(600, 'mike')
      @redis.verify
    end

    it 'schedules a job via timestamp' do
      @redis.expect :zadd, true, ['schedule', Array]
      assert ScheduledWorker.perform_in(5.days.from_now, 'mike')
      @redis.verify
    end

    it 'schedules job right away on negative timestamp/interval' do
      @redis.expect :sadd,  true, ['queues', 'custom_queue']
      @redis.expect :lpush, true, ['queue:custom_queue', Array]
      assert ScheduledWorker.perform_in(-300, 'mike')
      @redis.verify
    end

    it 'schedules multiple jobs at once' do
      @redis.expect :zadd, true, ['schedule', Array]
      assert Sidekiq::Client.push_bulk('class' => ScheduledWorker, 'args' => [['mike'], ['mike']], 'at' => 600)
      @redis.verify
    end
  end

end
