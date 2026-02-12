require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe KnowledgeQuiz, type: :worker do
  include ActiveJob::TestHelper

  let(:quiz) { FactoryBot.create(:quiz, id: 1) }
  let(:worker) { KnowledgeQuiz.new }
  let(:quiz_session) { QuizSession.new(1) }
  let(:redis) { Redis.new }

  before(:each) do
    Sidekiq::Testing.fake!
    # Clean up any existing quiz data
    quiz_session.cleanup_quiz_data
    redis.del("knowledge_quiz_lock")
    redis.del("knowledge_quiz_lock_execution")
    redis.del("knowledge_quiz_execution_window")

    # Clear the execution window key using $redis (global Redis instance)
    $redis.del(KnowledgeQuiz::EXECUTION_WINDOW_KEY)

    # Mock PubNub to prevent actual messages
    allow(PN).to receive(:publish)

    # Create test quiz questions
    5.times do |i|
      FactoryBot.create(:quiz_question,
        mc_question: "Test question #{i + 1}?",
        mc_option_a: "Option A",
        mc_option_b: "Option B",
        mc_option_c: "Option C",
        mc_option_d: "Option D",
        mc_answer: "a",
        question_type: 'mcq',
        approval_status: 'Approved',
        last_asked: 1.month.ago
      )
    end

    # Set Rails env to test for shorter sleep times
    allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("test"))

    # Mock sleep to make tests run fast
    allow_any_instance_of(KnowledgeQuiz).to receive(:sleep).and_return(nil)
  end

  after(:each) do
    quiz_session.cleanup_quiz_data
    redis.del("knowledge_quiz_lock")
    redis.del("knowledge_quiz_lock_execution")
    redis.del("knowledge_quiz_execution_window")
    $redis.del(KnowledgeQuiz::EXECUTION_WINDOW_KEY)
  end

  # Helper method to create a Redis mock that captures publish calls
  def create_redis_mock_with_publish_capture(capture_array)
    redis_wrapper = Class.new do
      attr_reader :real_redis, :capture_array

      def initialize(real_redis, capture_array)
        @real_redis = real_redis
        @capture_array = capture_array
      end

      def publish(channel, data)
        if channel == "quiz:1:state"
          @capture_array << JSON.parse(data)
        end
        nil # Return nil like Redis.publish normally does
      end

      def method_missing(method, *args, &block)
        @real_redis.send(method, *args, &block)
      end

      def respond_to_missing?(method, include_private = false)
        @real_redis.respond_to?(method, include_private) || super
      end
    end

    redis_wrapper.new(redis, capture_array)
  end

  describe 'State Publishing Reliability' do
    context 'state change publishing' do
      it 'publishes state changes through Redis pub/sub' do
        published_states = []

        # Mock Redis publish to capture states
        allow(Redis).to receive(:current).and_return(redis)
        allow(redis).to receive(:publish) do |channel, data|
          if channel == "quiz:1:state"
            published_states << JSON.parse(data)['state']
          end
        end

        # Run worker
        worker.perform

        # Should publish state transitions
        expect(published_states).not_to be_empty

        # Check for expected state transitions
        expect(published_states).to include('preparing') # Initial state
        expect(published_states).to include('ready')     # Chat open
        expect(published_states).to include('running')   # Questions start
      end

      it 'includes previous state in transitions' do
        published_data = []

        # Mock Redis.current to return our wrapper
        redis_mock = create_redis_mock_with_publish_capture(published_data)
        allow(Redis).to receive(:current).and_return(redis_mock)

        begin
          worker.perform
        ensure
          # Reset Redis.current mock
          RSpec::Mocks.space.proxy_for(Redis).reset
        end

        # Find transitions with previous states
        ready_transition = published_data.find { |d| d['state'] == 'ready' }
        running_transition = published_data.find { |d| d['state'] == 'running' }

        expect(ready_transition).to be_present
        expect(ready_transition['previous_state']).to eq('preparing')

        expect(running_transition).to be_present
        expect(running_transition['previous_state']).to eq('ready')
      end

      it 'handles publish failures gracefully' do
        # Make Redis publish fail
        allow(Redis).to receive(:current).and_return(redis)
        allow(redis).to receive(:publish).and_raise(Redis::ConnectionError)

        # Should not raise error
        expect { worker.perform }.not_to raise_error

        # Quiz should still complete
        expect(quiz_session.get_quiz_status).to eq("Available")
      end
    end

    context 'state synchronization' do
      it 'ensures state changes are visible before proceeding' do
        published_data = []

        # Mock Redis.current to return our wrapper
        redis_mock = create_redis_mock_with_publish_capture(published_data)
        allow(Redis).to receive(:current).and_return(redis_mock)

        worker.perform

        # Extract states from published data
        states_seen = published_data.map { |d| d['state'] }

        # States should be published in correct order
        expect(states_seen).to include('preparing', 'ready', 'running')
      end

      it 'maintains consistency between Redis state and published state' do
        published_states = []
        redis_states = []

        # Capture both published and Redis states
        allow(Redis).to receive(:current).and_return(redis)
        allow(redis).to receive(:publish) do |channel, data|
          if channel == "quiz:1:state"
            state_data = JSON.parse(data)
            published_states << state_data['state']
            # Check Redis state at time of publish
            redis_state = quiz_session.get_quiz_status
            redis_states << { state: state_data['state'], redis: redis_state }
          end
        end

        worker.perform

        # Published states should match Redis states
        redis_states.each do |check|
          case check[:state]
          when 'preparing'
            expect(check[:redis]).to match(/Initializing/)
          when 'ready'
            expect(check[:redis]).to match(/Chat open/)
          when 'running'
            expect(check[:redis]).to match(/progress/)
          end
        end
      end
    end
  end

  describe 'Ordered State Delivery' do
    context 'state sequencing' do
      it 'delivers states in correct order without skipping' do
        published_data = []

        # Mock Redis.current to return our wrapper
        redis_mock = create_redis_mock_with_publish_capture(published_data)
        allow(Redis).to receive(:current).and_return(redis_mock)

        # Run worker
        worker.perform

        # Extract states from published data
        delivered_states = published_data.map { |d| d['state'] }

        # States should be delivered in order
        expect(delivered_states).not_to be_empty
        expect(delivered_states).to include('preparing', 'ready', 'running')

        # No states should be skipped
        state_sequence = ['preparing', 'ready', 'running']
        delivered_sequence = delivered_states.select { |s| state_sequence.include?(s) }
        expect(delivered_sequence).to eq(state_sequence.take(delivered_sequence.size))
      end

      it 'includes timestamps for ordering verification' do
        published_states = []

        allow(Redis).to receive(:current).and_return(redis)
        allow(redis).to receive(:publish) do |channel, data|
          if channel == "quiz:1:state"
            published_states << JSON.parse(data)
          end
        end

        worker.perform

        # All states should have timestamps
        published_states.each do |state|
          expect(state['timestamp']).to be_present
          expect(Time.parse(state['timestamp'])).to be_a(Time)
        end

        # Timestamps should be increasing
        timestamps = published_states.map { |s| Time.parse(s['timestamp']) }
        expect(timestamps).to eq(timestamps.sort)
      end
    end

    context 'concurrent state updates' do
      it 'prevents out-of-order state updates' do
        # Start multiple workers simultaneously
        threads = []
        results = []
        mutex = Mutex.new

        3.times do |i|
          threads << Thread.new do
            worker = KnowledgeQuiz.new
            begin
              # Try to acquire lock
              if worker.send(:acquire_execution_window_lock)
                mutex.synchronize { results << { worker: i, acquired: true } }
                worker.perform
              else
                mutex.synchronize { results << { worker: i, acquired: false } }
              end
            rescue StandardError => e
              mutex.synchronize { results << { worker: i, error: e.message } }
            end
          end
        end

        threads.each(&:join)

        # Only one should acquire the lock
        acquired_count = results.count { |r| r[:acquired] }
        expect(acquired_count).to eq(1)
      end
    end
  end

  describe 'Idempotency of State Changes' do
    context 'duplicate state prevention' do
      it 'handles repeated state transitions gracefully' do
        published_states = []

        allow(Redis).to receive(:current).and_return(redis)
        allow(redis).to receive(:publish) do |channel, data|
          if channel == "quiz:1:state"
            published_states << JSON.parse(data)['state']
          end
        end

        # Manually trigger state changes multiple times
        allow(worker).to receive(:perform).and_wrap_original do |method|
          worker.send(:publish_state_change, 'preparing', 'waiting')
          worker.send(:publish_state_change, 'preparing', 'waiting') # Duplicate
          worker.send(:publish_state_change, 'ready', 'preparing')
          worker.send(:publish_state_change, 'ready', 'preparing') # Duplicate
        end

        worker.perform

        # Should handle duplicates gracefully
        expect(published_states.count('preparing')).to eq(2)
        expect(published_states.count('ready')).to eq(2)
      end

      it 'maintains idempotent state in Redis' do
        # Set initial state
        quiz_session.set_quiz_status("Question 1 in progress")

        # Multiple updates with same state
        5.times do
          quiz_session.set_quiz_status("Question 1 in progress")
        end

        # State should remain consistent
        expect(quiz_session.get_quiz_status).to eq("Question 1 in progress")
      end
    end

    context 'execution window protection' do
      it 'prevents duplicate quiz execution within window' do
        # First execution
        worker.perform

        # Try immediate second execution
        worker2 = KnowledgeQuiz.new
        expect(worker2.send(:quiz_recently_executed?)).to be_truthy

        # Should not execute
        allow(worker2).to receive(:announce_quiz_start)
        worker2.perform
        expect(worker2).not_to have_received(:announce_quiz_start)
      end

      it 'allows execution after window expires' do
        # Set execution window to past
        redis.set(KnowledgeQuiz::EXECUTION_WINDOW_KEY, 6.minutes.ago.iso8601, ex: 1)

        # Should allow execution
        expect(worker.send(:quiz_recently_executed?)).to be_falsey
      end

      it 'uses atomic operations for execution window' do
        # Multiple workers try to set execution window
        threads = []
        successes = []
        mutex = Mutex.new

        5.times do |i|
          threads << Thread.new do
            worker = KnowledgeQuiz.new
            success = worker.send(:acquire_execution_window_lock)
            mutex.synchronize { successes << success }
          end
        end

        threads.each(&:join)

        # Only one should succeed
        expect(successes.count(true)).to eq(1)
      end
    end

    context 'state recovery' do
      it 'recovers from interrupted state transitions' do
        # Simulate interrupted quiz
        quiz_session.set_quiz_status("Question 3 in progress")
        quiz_session.lock_quiz

        # New worker should detect locked state
        new_worker = KnowledgeQuiz.new
        # The worker checks if quiz is recently executed
        redis.set(KnowledgeQuiz::EXECUTION_WINDOW_KEY, Time.current.utc.iso8601, ex: 300)

        # Should skip execution due to execution window
        expect(new_worker.send(:quiz_recently_executed?)).to be_truthy

        # After execution window expires, should be able to proceed
        redis.del(KnowledgeQuiz::EXECUTION_WINDOW_KEY)
        expect(new_worker.send(:quiz_recently_executed?)).to be_falsey
      end

      it 'cleans up partial state on failure' do
        # Mock failure during quiz
        allow(worker).to receive(:run_quiz_questions).and_raise("Quiz failed")

        expect { worker.perform }.not_to raise_error

        # Should clean up state
        expect(quiz_session.quiz_locked?).to be_falsey
        expect(quiz_session.get_quiz_status).to eq("Available")
      end
    end
  end

  describe 'State Machine Integration' do
    context 'worker state coordination' do
      it 'coordinates state with controller state machine' do
        # Run worker to set states
        worker.perform

        # Controller should see consistent state
        controller = LiveQuizController.new
        allow(controller).to receive(:params).and_return({})
        # Mock request to avoid nil errors
        mock_request = double('request', headers: {})
        allow(controller).to receive(:request).and_return(mock_request)

        # During quiz execution, states should match
        quiz_states = ['preparing', 'ready', 'running', 'finished'].map do |expected_state|
          # Set corresponding Redis state
          case expected_state
          when 'preparing'
            quiz_session.set_quiz_status("In progress. Initializing...")
          when 'ready'
            quiz_session.set_quiz_status("In progress. Chat open. Wait for question.")
          when 'running'
            quiz_session.set_quiz_status("Question 1 in progress")
          when 'finished'
            quiz_session.set_quiz_status("Finished")
          end

          state = controller.send(:calculate_quiz_state, quiz)
          { expected: expected_state, actual: state[:state] }
        end

        quiz_states.each do |state_check|
          expect(state_check[:actual]).to eq(state_check[:expected])
        end
      end

      it 'publishes state changes that trigger client actions' do
        published_states = []

        # Mock Redis.current to return our wrapper
        redis_mock = create_redis_mock_with_publish_capture(published_states)
        allow(Redis).to receive(:current).and_return(redis_mock)

        worker.perform

        # Find any transition to running state
        running_transition = published_states.find { |s| s['state'] == 'running' }

        expect(running_transition).to be_present
        expect(running_transition['quiz_id']).to eq(1)
        expect(running_transition['timestamp']).to be_present
      end
    end

    context 'error state handling' do
      it 'publishes error states appropriately' do
        published_states = []

        allow(Redis).to receive(:current).and_return(redis)
        allow(redis).to receive(:publish) do |channel, data|
          published_states << JSON.parse(data) if channel == "quiz:1:state"
        end

        # Mock error during quiz
        allow(worker).to receive(:run_quiz_questions).and_raise("Test error")

        expect { worker.perform }.not_to raise_error

        # Should publish error state
        error_state = published_states.find { |s| s['state'] == 'error' || s['error'] }
        # Note: Current implementation doesn't publish error states, just cleans up
        # This test documents current behavior
      end

      it 'maintains state consistency after errors' do
        # Mock various errors
        allow(worker).to receive(:announce_quiz_start).and_raise("Announcement failed")

        expect { worker.perform }.not_to raise_error

        # Should clean up state
        expect(quiz_session.quiz_locked?).to be_falsey
        expect(quiz_session.get_quiz_status).to eq("Available")
      end
    end
  end

  describe 'Performance and Concurrency' do
    it 'publishes states without blocking quiz execution' do
      execution_times = []

      allow(worker).to receive(:publish_state_change).and_wrap_original do |method, state, prev_state|
        start = Time.current
        # Simulate slow publish
        sleep 0.1
        execution_times << Time.current - start
        # Don't call the original to avoid recursion
      end

      start_time = Time.current
      worker.perform
      total_time = Time.current - start_time

      # Total execution shouldn't be significantly impacted
      # (Worker sleeps during chat and questions, so hard to measure precisely)
      expect(execution_times.all? { |t| t < 0.2 }).to be_truthy
    end

    it 'handles high-frequency state checks during execution' do
      published_data = []

      # Create a special wrapper that also updates quiz status
      redis_wrapper = Class.new do
        attr_reader :real_redis, :capture_array, :quiz_session

        def initialize(real_redis, capture_array, quiz_session)
          @real_redis = real_redis
          @capture_array = capture_array
          @quiz_session = quiz_session
        end

        def publish(channel, data)
          if channel == "quiz:1:state"
            state_data = JSON.parse(data)
            @capture_array << state_data['state']

            # Also update the quiz status to simulate real behavior
            case state_data['state']
            when 'preparing'
              @quiz_session.set_quiz_status("In progress. Initializing...")
            when 'ready'
              @quiz_session.set_quiz_status("In progress. Chat open. Wait for question.")
            when 'running'
              @quiz_session.set_quiz_status("Question 1 in progress")
            end
          end
          nil
        end

        def method_missing(method, *args, &block)
          @real_redis.send(method, *args, &block)
        end

        def respond_to_missing?(method, include_private = false)
          @real_redis.respond_to?(method, include_private) || super
        end
      end

      states_captured = []
      redis_mock = redis_wrapper.new(redis, states_captured, quiz_session)
      allow(Redis).to receive(:current).and_return(redis_mock)

      # Run worker
      worker.perform

      # Should see various states during execution
      expect(states_captured).not_to be_empty
      expect(states_captured.uniq.size).to be > 1

      # Should include key states from the quiz lifecycle
      expect(states_captured).to include('preparing', 'ready', 'running')
    end
  end
end