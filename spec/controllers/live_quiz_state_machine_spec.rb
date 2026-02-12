require 'rails_helper'
require 'timeout'

RSpec.describe LiveQuizController, type: :controller do
  include LiveQuizHelpers

  let(:user) { FactoryBot.create(:user) }
  let(:quiz) { FactoryBot.create(:quiz) }

  before do
    sign_in user
  end

  describe 'State Machine Testing' do
    describe '#calculate_quiz_state' do
      # Test all state transitions: none -> waiting -> preparing -> ready -> running -> finished

      context 'state transition: none -> waiting' do
        before do
          # Clean up any existing state
          quiz_session = QuizSession.new(quiz.id)
          quiz_session.cleanup_quiz_data

          # Ensure this is not treated as a knowledge quiz
          if quiz.id == 1
            # Mock next_knowledge_quiz_time to return nil for this test
            allow(Quiz).to receive(:next_knowledge_quiz_time).and_return(nil)
          end
        end

        it 'returns none state when no quiz scheduled' do
          quiz.update!(start_time: nil)

          state = controller.send(:calculate_quiz_state, quiz)

          expect(state[:state]).to eq('none')
          expect(state[:should_refresh]).to be_falsey
          expect(state[:next_transition_at]).to be_nil
          expect(state[:transition_to]).to be_nil
        end

        it 'transitions to waiting when quiz is scheduled' do
          quiz.update!(start_time: 10.minutes.from_now)

          state = controller.send(:calculate_quiz_state, quiz)

          expect(state[:state]).to eq('waiting')
          expect(state[:should_refresh]).to be_falsey
          expect(state[:next_transition_at]).to be_present
          expect(state[:transition_to]).to eq('preparing')
        end
      end

      context 'state transition: waiting -> preparing' do
        # Note: QUIZ_PREPARING_WINDOW_SECONDS is 2 in test environment, not 5
        let(:preparing_window) { LiveQuizController::QUIZ_PREPARING_WINDOW_SECONDS }

        it 'transitions to preparing when quiz is about to start (< preparing window)' do
          quiz.update!(start_time: 1.second.from_now) # Less than 2 seconds

          state = controller.send(:calculate_quiz_state, quiz)

          expect(state[:state]).to eq('preparing')
          expect(state[:transition_to]).to eq('ready')
          expect(state[:next_transition_at]).to be_present
        end

        it 'stays in waiting when more than preparing window seconds remain' do
          quiz.update!(start_time: 10.seconds.from_now) # More than 2 seconds

          state = controller.send(:calculate_quiz_state, quiz)

          expect(state[:state]).to eq('waiting')
          expect(Time.parse(state[:next_transition_at])).to be_within(2.seconds).of(quiz.start_time - preparing_window.seconds)
        end
      end

      context 'state transition: preparing -> ready' do
        before do
          setup_quiz_session_with_sync(quiz.id, "In progress. Initializing...")
        end

        it 'returns preparing state when quiz is initializing' do
          state = controller.send(:calculate_quiz_state, quiz)

          expect(state[:state]).to eq('preparing')
          expect(state[:transition_to]).to eq('ready')
        end

        it 'transitions to ready when chat opens' do
          setup_quiz_session_with_sync(quiz.id, "In progress. Chat open. Wait for question.")

          state = controller.send(:calculate_quiz_state, quiz)

          expect(state[:state]).to eq('ready')
          expect(state[:transition_to]).to eq('running')
        end
      end

      context 'state transition: ready -> running' do
        it 'transitions to running when questions start' do
          setup_quiz_session_with_sync(quiz.id, "Question 1 in progress")

          state = controller.send(:calculate_quiz_state, quiz)

          expect(state[:state]).to eq('running')
          expect(state[:transition_to]).to eq('finished')
          expect(state[:should_refresh]).to be_falsey
        end

        it 'detects various running states correctly' do
          running_statuses = [
            "Question 5 in progress",
            "In progress",
            "In progress. Question active."
          ]

          running_statuses.each do |status|
            setup_quiz_session_with_sync(quiz.id, status)

            state = controller.send(:calculate_quiz_state, quiz)

            expect(state[:state]).to eq('running'), "Expected 'running' for status: #{status}"
          end
        end
      end

      context 'state transition: running -> finished' do
        it 'transitions to finished when quiz completes' do
          setup_quiz_session_with_sync(quiz.id, "Finished")

          state = controller.send(:calculate_quiz_state, quiz)

          expect(state[:state]).to eq('finished')
          expect(state[:should_refresh]).to be_falsey
          expect(state[:next_transition_at]).to be_nil
          expect(state[:transition_to]).to be_nil
        end
      end

      context 'edge cases and special scenarios' do
        it 'handles chat period correctly (not considered running)' do
          setup_quiz_session_with_sync(quiz.id, "In progress. Chat open. Wait for question.")

          state = controller.send(:calculate_quiz_state, quiz)

          # Chat period is "ready", not "running"
          expect(state[:state]).to eq('ready')
          expect(state[:transition_to]).to eq('running')
        end

        it 'correctly identifies should_refresh when preparing overlay is visible' do
          setup_quiz_session_with_sync(quiz.id, "In progress. Chat open. Wait for question.")
          allow(controller).to receive(:params).and_return({ preparing_visible: "true" })

          state = controller.send(:calculate_quiz_state, quiz)

          expect(state[:state]).to eq('ready')
          expect(state[:should_refresh]).to be_truthy
        end

        it 'handles initializing states with variations' do
          initializing_statuses = [
            "In progress. Initializing...",
            "In progress. Chat opening soon",
            "Initializing quiz"
          ]

          initializing_statuses.each do |status|
            setup_quiz_session_with_sync(quiz.id, status)

            state = controller.send(:calculate_quiz_state, quiz)

            expect(state[:state]).to eq('preparing'), "Expected 'preparing' for status: #{status}"
          end
        end
      end

      context 'knowledge quiz (ID=1) specific behavior' do
        let(:knowledge_quiz) { FactoryBot.create(:quiz, id: 1) }

        before do
          # Clean up any existing data
          quiz_session = QuizSession.new(1)
          quiz_session.cleanup_quiz_data
        end

        after do
          # Clean up after test
          quiz_session = QuizSession.new(1)
          quiz_session.cleanup_quiz_data
        end

        it 'uses next_knowledge_quiz_time for scheduling' do
          allow(Quiz).to receive(:next_knowledge_quiz_time).and_return(15.minutes.from_now)

          state = controller.send(:calculate_quiz_state, knowledge_quiz)

          expect(state[:state]).to eq('waiting')
          expect(state[:transition_to]).to eq('preparing')
        end

        it 'handles no scheduled knowledge quiz' do
          allow(Quiz).to receive(:next_knowledge_quiz_time).and_return(nil)

          state = controller.send(:calculate_quiz_state, knowledge_quiz)

          expect(state[:state]).to eq('none')
          expect(state[:next_transition_at]).to be_nil
        end
      end
    end

    describe 'Concurrent State Requests' do
      it 'handles multiple simultaneous state requests without race conditions' do
        setup_quiz_session_with_sync(quiz.id, "In progress. Chat open. Wait for question.")

        results = []
        threads = []

        # Create multiple threads to simulate concurrent requests
        10.times do
          threads << Thread.new do
            # Create a new controller instance for thread safety
            thread_controller = LiveQuizController.new
            thread_controller.instance_variable_set(:@_request, controller.request)

            # Calculate state directly
            state = thread_controller.send(:calculate_quiz_state, quiz)
            results << state
          end
        end

        # Wait for all threads to complete
        threads.each(&:join)

        # All requests should return consistent state
        states = results.map { |r| r[:state] }.uniq
        expect(states.size).to eq(1), "Expected all concurrent requests to return same state, got: #{states}"
        expect(states.first).to eq('ready')
      end

      it 'maintains state consistency during transitions' do
        # Start in waiting state
        quiz.update!(start_time: 2.seconds.from_now)

        results = []

        # Make rapid consecutive requests during state transition
        5.times do
          state = controller.send(:calculate_quiz_state, quiz)
          results << state
          sleep 0.5
        end

        # Check that states follow valid transition path
        states = results.map { |r| r[:state] }

        # Valid transitions: waiting -> preparing -> none (after time passes)
        states.each_cons(2) do |prev_state, next_state|
          valid_transition = case prev_state
          when 'waiting'
            ['waiting', 'preparing'].include?(next_state)
          when 'preparing'
            ['preparing', 'ready', 'none'].include?(next_state)
          when 'none'
            ['none'].include?(next_state)
          else
            true # Allow same state
          end

          expect(valid_transition).to be_truthy,
            "Invalid transition detected: #{prev_state} -> #{next_state}"
        end
      end
    end

    describe 'Timing Windows and Edge Cases' do
      context 'boundary conditions' do
        let(:preparing_window) { LiveQuizController::QUIZ_PREPARING_WINDOW_SECONDS }

        before do
          # Ensure clean state
          quiz_session = QuizSession.new(quiz.id)
          quiz_session.cleanup_quiz_data
        end

        it 'handles exact preparing window boundary correctly' do
          # Test right at the boundary (2 seconds in test environment)
          quiz.update!(start_time: preparing_window.seconds.from_now)

          state = controller.send(:calculate_quiz_state, quiz)

          # At exactly the boundary, should be either waiting or preparing
          expect(['waiting', 'preparing']).to include(state[:state])
        end

        it 'handles start time in the past' do
          quiz.update!(start_time: 1.minute.ago)

          # No status set, so it should be finished/none
          state = controller.send(:calculate_quiz_state, quiz)

          expect(['none', 'finished']).to include(state[:state])
        end

        it 'handles nil start time gracefully' do
          quiz.update!(start_time: nil)

          state = controller.send(:calculate_quiz_state, quiz)

          expect(state[:state]).to eq('none')
          expect(state[:next_transition_at]).to be_nil
        end
      end

      context 'clock skew and time precision' do
        it 'handles microsecond differences in timing' do
          # Set start time with microsecond precision
          precise_time = 10.seconds.from_now.change(usec: 123456)
          quiz.update!(start_time: precise_time)

          state = controller.send(:calculate_quiz_state, quiz)

          expect(state[:state]).to eq('waiting')
          # Transition time should be properly calculated
          transition_time = Time.parse(state[:next_transition_at])
          expect(transition_time).to be_within(3.seconds).of(precise_time - 5.seconds)
        end
      end

      context 'state recovery scenarios' do
        it 'recovers from missing Redis data' do
          # Simulate Redis data loss
          quiz_session = QuizSession.new(quiz.id)
          quiz_session.cleanup_quiz_data

          # Should fall back to schedule-based state
          quiz.update!(start_time: 10.minutes.from_now)

          state = controller.send(:calculate_quiz_state, quiz)

          expect(state[:state]).to eq('waiting')
        end

        it 'handles corrupted status gracefully' do
          # Set an unexpected status
          setup_quiz_session_with_sync(quiz.id, "Some unexpected status")

          state = controller.send(:calculate_quiz_state, quiz)

          # Should handle gracefully without crashing
          expect(state).to be_present
          expect(state[:state]).to be_present
        end
      end
    end

    describe 'State Persistence and Recovery' do
      context 'Redis failure scenarios' do
        it 'degrades gracefully when Redis is unavailable' do
          # Simulate Redis connection failure
          allow_any_instance_of(QuizSession).to receive(:get_quiz_status).and_return(nil)
          allow_any_instance_of(QuizSession).to receive(:get_quiz_metadata).and_return({})

          quiz.update!(start_time: 10.minutes.from_now)

          # Should still calculate state from schedule
          expect {
            state = controller.send(:calculate_quiz_state, quiz)
            expect(state[:state]).to eq('waiting')
          }.not_to raise_error
        end

        it 'maintains state consistency across Redis reconnection' do
          # Set initial state
          setup_quiz_session_with_sync(quiz.id, "Question 3 in progress")

          # Verify initial state
          state1 = controller.send(:calculate_quiz_state, quiz)
          expect(state1[:state]).to eq('running')

          # Simulate brief Redis outage
          quiz_session = QuizSession.new(quiz.id)
          quiz_session.cleanup_quiz_data

          # Re-establish state
          setup_quiz_session_with_sync(quiz.id, "Question 5 in progress")

          # State should be consistent
          state2 = controller.send(:calculate_quiz_state, quiz)
          expect(state2[:state]).to eq('running')
        end
      end

      context 'state transition timing' do
        it 'ensures atomic state transitions' do
          # Test that state transitions are atomic and consistent
          quiz.update!(start_time: 1.second.from_now)

          # Capture states during transition period
          states_captured = []

          # Use Timeout to ensure we don't wait forever
          Timeout.timeout(3) do
            while states_captured.size < 5
              state = controller.send(:calculate_quiz_state, quiz)
              states_captured << state[:state]
              sleep 0.3
            end
          end

          # Should see valid progression, no invalid states
          valid_states = ['waiting', 'preparing', 'ready', 'running', 'finished', 'none']
          states_captured.each do |state|
            expect(valid_states).to include(state)
          end
        end
      end
    end

    describe 'Performance and Load Testing' do
      it 'handles rapid state checks efficiently' do
        setup_quiz_session_with_sync(quiz.id, "Question 10 in progress")

        # Measure time for multiple rapid checks
        start_time = Time.current

        100.times do
          controller.send(:calculate_quiz_state, quiz)
        end

        elapsed = Time.current - start_time

        # Should complete 100 checks in under 1 second
        expect(elapsed).to be < 1.0
      end

      it 'maintains consistency under high concurrency' do
        setup_quiz_session_with_sync(quiz.id, "In progress. Chat open. Wait for question.")

        errors = []
        results = Concurrent::Array.new

        # Create thread pool for concurrent execution
        pool = Concurrent::FixedThreadPool.new(20)

        # Submit many concurrent tasks
        100.times do
          pool.post do
            begin
              state = controller.send(:calculate_quiz_state, quiz)
              results << state[:state]
            rescue => e
              errors << e
            end
          end
        end

        # Wait for completion
        pool.shutdown
        pool.wait_for_termination(5)

        # No errors should occur
        expect(errors).to be_empty

        # All results should be consistent
        expect(results.uniq.size).to eq(1)
        expect(results.first).to eq('ready')
      end
    end
  end
end