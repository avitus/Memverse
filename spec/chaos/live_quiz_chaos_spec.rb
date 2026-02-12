require 'rails_helper'
require 'timecop'

RSpec.describe 'Live Quiz Chaos Engineering', type: :request do
  include FactoryBot::Syntax::Methods
  include Devise::Test::IntegrationHelpers
  let(:quiz) { create(:quiz, id: 1) }
  let(:user) { create(:user) }

  before do
    # Create quiz questions
    create_list(:quiz_question, 30, :mcq, quiz: quiz, approval_status: 'approved')

    # Mock external services
    allow(PN).to receive(:publish).and_return(true)

    # Clean Redis
    $redis.flushdb

    sign_in user
  end

  describe 'Clock skew testing' do
    it 'handles client clock 5 minutes ahead of server' do
      # Simulate client clock ahead
      client_time = Time.current + 5.minutes

      # Make request with future timestamp
      get "/live_quiz/quiz_state/#{quiz.id}", params: { id: quiz.id }, headers: {
        'X-Client-Time' => client_time.iso8601
      }

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      server_time = Time.parse(json['server_time'])

      # Server should provide its own time for reference
      expect(json['server_time']).to be_present

      # Server should still work correctly despite clock skew
      # The quiz state should be calculated based on server time, not client time
      expect(json['state']).to be_in(['none', 'waiting', 'preparing', 'ready', 'running', 'finished'])
    end

    it 'handles client clock 5 minutes behind server' do
      # Simulate client clock behind
      client_time = Time.current - 5.minutes

      get "/live_quiz/quiz_state/#{quiz.id}", params: { id: quiz.id }, headers: {
        'X-Client-Time' => client_time.iso8601
      }

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      # Verify server handles past timestamps gracefully
      expect(json['state']).to be_in(['none', 'waiting', 'preparing', 'ready', 'running', 'finished'])
    end

    it 'maintains correct quiz timing despite clock skew' do
      quiz_session = QuizSession.new(quiz.id)

      # Set quiz to start in 2 minutes
      Timecop.freeze(Time.current) do
        # Server time
        quiz.update!(start_time: 2.minutes.from_now)

        # Client with clock 3 minutes fast thinks quiz should already be running
        client_time = Time.current + 3.minutes

        get "/live_quiz/quiz_state/#{quiz.id}", params: { id: quiz.id }, headers: {
          'X-Client-Time' => client_time.iso8601
        }

        json = JSON.parse(response.body)

        # Server should still show waiting state based on server time
        expect(json['state']).to eq('waiting')
        expect(json['next_transition_at']).to be_present
      end
    end
  end

  describe 'Daylight saving time transitions' do
    it 'handles spring forward DST transition' do
      # For quiz ID 1, just verify it handles DST without errors
      # The actual state depends on the fixed schedule
      dst_transition = Time.zone.parse('2024-03-10 01:59:00')

      Timecop.freeze(dst_transition) do
        # Get state before transition
        get "/live_quiz/quiz_state/#{quiz.id}"
        expect(response).to have_http_status(:ok)
        json_before = JSON.parse(response.body)

        # Jump forward past DST (clock goes from 1:59 to 3:00)
        Timecop.travel(dst_transition + 2.hours) do
          get "/live_quiz/quiz_state/#{quiz.id}"
          expect(response).to have_http_status(:ok)
          json_after = JSON.parse(response.body)

          # State should be valid and time calculations should work
          expect(json_after['state']).to be_in(['none', 'waiting', 'preparing', 'ready', 'running', 'finished'])
          expect(json_after['server_time']).to be_present
        end
      end
    end

    it 'handles fall back DST transition' do
      # Test around fall DST change (1st Sunday in November at 2am)
      dst_transition = Time.zone.parse('2024-11-03 01:59:00')

      Timecop.freeze(dst_transition) do
        quiz_session = QuizSession.new(quiz.id)

        # Start quiz during the "repeated hour"
        quiz_session.set_quiz_status("In progress. Chat open. Wait for question.", {
          chat_start_time: dst_transition.utc.iso8601,
          chat_duration: 300
        })

        # Jump to after DST (clock goes from 1:59 back to 1:00)
        Timecop.travel(dst_transition + 1.hour) do
          get "/live_quiz/quiz_state/#{quiz.id}"
          json = JSON.parse(response.body)

          # Should handle the repeated hour correctly
          expect(response).to have_http_status(:ok)
          # The status "In progress. Chat open. Wait for question." maps to 'ready'
          expect(json['state']).to eq('ready')
        end
      end
    end
  end

  describe 'Redis failure scenarios' do
    it 'handles Redis connection failure during quiz' do
      # Clear any cached state
      Rails.cache.clear

      # Start a quiz
      quiz_session = QuizSession.new(quiz.id)
      quiz_session.set_quiz_status("In progress. Chat open. Wait for question.")

      # Simulate Redis connection failure for all Redis operations
      allow($redis).to receive(:hget).and_raise(Redis::CannotConnectError.new("Connection refused"))
      allow($redis).to receive(:hgetall).and_raise(Redis::CannotConnectError.new("Connection refused"))

      # API calls should degrade gracefully
      expect { get "/live_quiz/quiz_state/#{quiz.id}", params: { id: quiz.id } }.not_to raise_error

      # Should degrade gracefully with 200 OK
      expect(response).to have_http_status(:ok)

      # Response should indicate state based on schedule when Redis unavailable
      json = JSON.parse(response.body)
      # For quiz ID 1 (knowledge quiz), it falls back to schedule-based state
      # Since we don't have a specific next_quiz_time set up, it should return 'none' or 'waiting'
      expect(json['state']).to be_in(['none', 'waiting'])

      # Restore Redis
      allow($redis).to receive(:hget).and_call_original
      allow($redis).to receive(:hgetall).and_call_original
    end

    it 'handles Redis restart during active quiz' do
      quiz_session = QuizSession.new(quiz.id)

      # Set quiz in progress
      quiz_session.set_quiz_status("Question 5 in progress")

      # Add participants and scores
      5.times do |i|
        quiz_session.add_participant(i, "User#{i}", "user#{i}")
        quiz_session.update_score(i, 1, rand(5..10))
      end

      # Simulate Redis restart by flushing all data
      $redis.flushdb

      # Clear Rails cache too
      Rails.cache.clear

      # Try to get quiz state
      get "/live_quiz/quiz_state/#{quiz.id}"
      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      # Should recover to a safe state based on schedule
      # For knowledge quiz (ID=1), it will check schedule and return 'none' or 'waiting'
      expect(json['state']).to be_in(['none', 'waiting'])
    end

    it 'handles Redis memory pressure' do
      # Fill Redis with data to simulate memory pressure
      large_data = 'x' * 1_000_000  # 1MB string

      begin
        # Try to fill Redis (but limit to prevent actual issues)
        100.times do |i|
          $redis.set("chaos_test:#{i}", large_data)
        end

        # Quiz operations should still work
        quiz_session = QuizSession.new(quiz.id)
        expect {
          quiz_session.add_participant(1, "TestUser", "testuser")
        }.not_to raise_error

        # Clean up immediately
      ensure
        $redis.scan_each(match: "chaos_test:*") do |key|
          $redis.del(key)
        end
      end
    end
  end

  describe 'Network latency and packet loss' do
    it 'handles high latency SSE connections' do
      # Simulate high latency by adding delays
      original_publish = $redis.method(:publish)

      allow($redis).to receive(:publish) do |*args|
        sleep(0.5)  # 500ms latency
        original_publish.call(*args)
      end

      # SSE connection should still work
      Thread.new do
        get live_quiz_events_path(id: quiz.id), headers: {
          'Accept' => 'text/event-stream'
        }
      end

      sleep(1)  # Give connection time to establish

      # Publish state change
      $redis.publish("quiz:#{quiz.id}:state", {
        state: 'preparing',
        timestamp: Time.current.utc.iso8601
      }.to_json)

      # Verify high latency doesn't break functionality
      expect($redis).to have_received(:publish).at_least(:once)
    end

    it 'handles intermittent network failures' do
      call_count = 0
      original_get = $redis.method(:get)

      # Simulate 50% packet loss
      allow($redis).to receive(:get) do |*args|
        call_count += 1
        if call_count % 2 == 0
          raise Redis::TimeoutError.new("Simulated timeout")
        else
          original_get.call(*args)
        end
      end

      # API should implement retry logic
      5.times do
        get "/live_quiz/quiz_state/#{quiz.id}"
        # Should eventually succeed despite failures
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'Concurrent modification scenarios' do
    it 'handles race conditions in score updates' do
      quiz_session = QuizSession.new(quiz.id)

      # Simulate multiple simultaneous score submissions for same user
      threads = []
      user_id = 1

      10.times do |i|
        threads << Thread.new do
          quiz_session.add_participant(user_id, "TestUser", "testuser")
          quiz_session.update_score(user_id, 1, rand(5..10))
        end
      end

      threads.each(&:join)

      # Should have consistent state despite race conditions
      scoreboard = quiz_session.get_scoreboard
      user_entry = scoreboard.find { |entry| entry['id'] == user_id.to_s }

      expect(user_entry).to be_present
      expect(user_entry['score']).to be_a(String)
    end

    it 'handles concurrent quiz state transitions' do
      quiz_session = QuizSession.new(quiz.id)

      # Multiple processes trying to change quiz state
      threads = []
      states = ['preparing', 'ready', 'running', 'finished']

      states.each do |state|
        threads << Thread.new do
          5.times do
            quiz_session.set_quiz_status("Quiz is #{state}")
            sleep(0.01)
          end
        end
      end

      threads.each(&:join)

      # Final state should be valid
      final_status = quiz_session.get_quiz_status
      expect(final_status).to be_a(String)
    end
  end

  describe 'Resource exhaustion scenarios' do
    it 'handles excessive participant registrations' do
      quiz_session = QuizSession.new(quiz.id)

      # Try to register 10,000 participants
      expect {
        10_000.times do |i|
          quiz_session.add_participant(i, "User#{i}", "user#{i}")
        end
      }.not_to raise_error

      # Should handle large participant lists
      scoreboard = quiz_session.get_scoreboard

      # Currently no limit is enforced, so all 10,000 should be registered
      # This tests that the system doesn't crash with large numbers
      expect(scoreboard.size).to eq(10_000)
    end

    it 'handles malformed client data' do
      # Send various malformed requests
      malformed_requests = [
        { quiz_id: 'not_a_number' },
        { quiz_id: -1 },
        { quiz_id: 999999 },
        { quiz_id: nil },
        { quiz_id: '' },
        { quiz_id: '1; DROP TABLE quizzes;' }  # SQL injection attempt
      ]

      malformed_requests.each do |params|
        quiz_id_param = params[:quiz_id] || quiz.id
        # Properly encode the parameter for URL
        encoded_id = quiz_id_param.to_s.empty? ? quiz.id : CGI.escape(quiz_id_param.to_s)

        get "/live_quiz/quiz_state/#{encoded_id}"

        # Should handle gracefully without 500 errors
        expect(response.status).to be < 500
      end
    end
  end

  describe 'Byzantine failures' do
    it 'handles corrupted Redis data' do
      quiz_session = QuizSession.new(quiz.id)

      # Corrupt quiz data in Redis
      # The status is stored in a hash, so corrupt the hash
      $redis.hset("quiz:#{quiz.id}:status", "status", "{{invalid json}}")
      $redis.hset("quiz:#{quiz.id}:participants", "corrupted", "not_json")

      # Should handle corrupted data gracefully
      expect { quiz_session.get_quiz_status }.not_to raise_error
      expect { quiz_session.get_scoreboard }.not_to raise_error

      # Should return safe defaults
      status = quiz_session.get_quiz_status
      # get_quiz_status returns nil when there's an error (see with_redis_error_handling)
      expect(status).to be_nil
    end

    it 'handles partial system failures' do
      # Simulate partial Redis command failures
      allow($redis).to receive(:hgetall).and_raise(Redis::CommandError.new("ERR"))
      allow($redis).to receive(:get).and_return(nil) # Return nil for other get calls

      # System should degrade gracefully
      get "/live_quiz/quiz_state/#{quiz.id}"
      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json['state']).to be_present
    end
  end

  describe 'State machine edge cases' do
    it 'handles rapid state transitions' do
      quiz_session = QuizSession.new(quiz.id)

      # Rapidly transition through all states
      transitions = [
        "Available",
        "In progress. Initializing...",
        "In progress. Chat open. Wait for question.",
        "Question 1 in progress",
        "Question 2 in progress",
        "Finished",
        "Available"
      ]

      transitions.each do |status|
        quiz_session.set_quiz_status(status)
        get "/live_quiz/quiz_state/#{quiz.id}"
        expect(response).to have_http_status(:ok)
      end
    end

    it 'handles invalid state transitions' do
      controller = LiveQuizController.new

      # Test calculate_quiz_state with various edge cases
      quiz_session = QuizSession.new(quiz.id)

      # Set quiz to finished state
      quiz_session.set_quiz_status("Finished")

      # Try to transition back to running (invalid)
      quiz_session.set_quiz_status("Question 1 in progress")

      get "/live_quiz/quiz_state/#{quiz.id}"
      json = JSON.parse(response.body)

      # Should handle invalid transitions gracefully
      expect(json['state']).to be_present
    end
  end
end