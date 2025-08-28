require 'spec_helper'

RSpec.describe KnowledgeQuiz, type: :worker do
  let(:worker) { described_class.new }
  let(:user) { User.create!(name: "Test User", email: "test@example.com", password: "password", password_confirmation: "password") }
  let(:quiz) { Quiz.create!(id: 1, name: "Bible Knowledge Quiz", user: user) }
  let(:quiz_session) { instance_double(QuizSession) }
  let(:question) { instance_double(QuizQuestion, id: 123, time_allocation: 30, mc_question: "Test?", mc_option_a: "A", mc_option_b: "B", mc_option_c: "C", mc_option_d: "D", mc_answer: "A") }
  let(:next_quiz_time) { 1.week.from_now.utc }

  before do
    # Ensure Quiz 1 exists for knowledge quiz
    quiz
    
    # Mock Quiz.find to return our quiz instance for update calls
    allow(Quiz).to receive(:find).with(1).and_return(quiz)

    # Mock QuizSession service
    allow(QuizSession).to receive(:new).with(1).and_return(quiz_session)
    allow(quiz_session).to receive(:lock_quiz).and_return(true)
    allow(quiz_session).to receive(:unlock_quiz).and_return(true)
    allow(quiz_session).to receive(:quiz_in_progress?).and_return(false)
    allow(quiz_session).to receive(:set_quiz_status).and_return(true)
    allow(quiz_session).to receive(:cleanup_quiz_data).and_return(true)
    allow(quiz_session).to receive(:cleanup_legacy_data).and_return(true)
    allow(quiz_session).to receive(:update_question_stats).and_return(true)
    allow(quiz_session).to receive(:get_scoreboard).and_return([])
    allow(quiz_session).to receive(:get_question_stats).and_return([])
    allow(quiz_session).to receive(:get_quiz_metadata).and_return({"success_count" => "5"})

    # Mock Redis for direct Redis calls (chat status, etc.)
    allow($redis).to receive(:exists).and_return(false)
    allow($redis).to receive(:hmget).and_return([nil])
    allow($redis).to receive(:hset).and_return(true)

    # Mock PubNub to avoid network calls
    allow(PN).to receive(:publish).and_return(true)

    # Mock Tweet creation
    allow(Tweet).to receive(:create!).and_return(true)

    # Mock iOS push notifications
    allow(worker).to receive(:ios_quiz_alert).and_return(true)

    # Mock QuizQuestion queries
    allow(QuizQuestion).to receive_message_chain(:mcq, :approved, :order, :first).and_return(nil)
    allow(question).to receive(:update!).and_return(true)
    allow(question).to receive(:update_difficulty).and_return(true)

    # Mock IceCube scheduling
    mock_schedule = double('schedule')
    allow(mock_schedule).to receive(:next_occurrence).and_return(next_quiz_time)
    allow(IceCube::Schedule).to receive(:new).and_return(mock_schedule)
    allow(mock_schedule).to receive(:add_recurrence_rule).and_return(true)

    # Mock sleep to speed up tests - allow any sleep call
    allow(worker).to receive(:sleep).and_return(nil)

    # Mock Rails environment
    allow(Rails.env).to receive(:production?).and_return(false)
    
    # Disable actual logging output in tests
    allow(Sidekiq.logger).to receive(:info)
    allow(Sidekiq.logger).to receive(:warn)
    allow(Sidekiq.logger).to receive(:error)
    allow(Sidekiq.logger).to receive(:debug)
  end

  describe '#perform' do
    context 'when successful execution flow' do
      it 'completes the quiz workflow successfully' do
        expect(Sidekiq.logger).to receive(:info).with(/Knowledge Quiz Worker starting/)
        expect(Sidekiq.logger).to receive(:info).with(/Knowledge Quiz completed successfully/)
        
        worker.perform
      end

      it 'acquires and releases quiz lock' do
        expect(quiz_session).to receive(:lock_quiz).with(KnowledgeQuiz::LOCK_TIMEOUT).and_return(true)
        expect(quiz_session).to receive(:unlock_quiz).at_least(:once)
        
        worker.perform
      end

      it 'sets up quiz status correctly throughout lifecycle' do
        expect(quiz_session).to receive(:set_quiz_status).with("In progress. Initializing...", hash_including(:start_time))
        expect(quiz_session).to receive(:set_quiz_status).with("In progress. Wait for question.")
        expect(quiz_session).to receive(:set_quiz_status).with("Finished", hash_including(:end_time))
        expect(quiz_session).to receive(:set_quiz_status).with("Available", hash_including(:last_success, :duration_seconds, :success_count))
        
        worker.perform
      end

      it 'announces quiz start with tweet and push notification' do
        expect(Tweet).to receive(:create!).with(
          news: "The Bible knowledge quiz is starting. <a href=\"live_quiz\">Join now!</a>",
          user_id: 1,
          importance: 2
        )
        expect(worker).to receive(:ios_quiz_alert).with("The Bible trivia quiz is starting now.")
        
        worker.perform
      end

      it 'cleans up quiz data before starting' do
        expect(quiz_session).to receive(:cleanup_quiz_data)
        expect(quiz_session).to receive(:cleanup_legacy_data)
        
        worker.perform
      end

      it 'manages chat channel lifecycle' do
        expect($redis).to receive(:hset).with("chat-quiz-1", "status", "Open")
        expect($redis).to receive(:hset).with("chat-quiz-1", "status", "Closed")
        
        worker.perform
      end

      it 'publishes chat status changes to PubNub' do
        expect(PN).to receive(:publish).with(
          hash_including(
            channel: "quiz-1",
            message: hash_including(meta: "chat_status", status: "Open")
          )
        )
        expect(PN).to receive(:publish).with(
          hash_including(
            channel: "quiz-1",
            message: hash_including(meta: "chat_status", status: "Closed")
          )
        )
        
        worker.perform
      end

      it 'calculates and stores next quiz time' do
        expect(quiz).to receive(:update!).with(start_time: next_quiz_time)
        
        worker.perform
      end
    end

    context 'when quiz is already in progress' do
      before do
        allow(quiz_session).to receive(:quiz_in_progress?).and_return(true)
      end

      it 'aborts execution gracefully' do
        expect(Sidekiq.logger).to receive(:warn).with(/Knowledge quiz already in progress, aborting/)
        
        worker.perform
      end

      it 'does not run the main quiz logic' do
        expect(worker).not_to receive(:setup_quiz_environment)
        expect(worker).not_to receive(:run_quiz_questions)
        
        worker.perform
      end

      it 'still releases the lock' do
        expect(quiz_session).to receive(:unlock_quiz)
        
        worker.perform
      end
    end

    context 'when lock cannot be acquired' do
      before do
        allow(quiz_session).to receive(:lock_quiz).and_return(false)
      end

      it 'aborts execution gracefully' do
        expect(Sidekiq.logger).to receive(:warn).with(/Knowledge quiz already running, aborting this execution/)
        
        worker.perform
      end

      it 'does not proceed with quiz setup' do
        expect(worker).not_to receive(:setup_quiz_environment)
        
        worker.perform
      end
    end

    context 'when database errors occur during initialization' do
      before do
        allow(Quiz).to receive(:find).and_raise(ActiveRecord::RecordNotFound.new("Quiz not found"))
      end

      it 'handles errors gracefully' do
        expect(Sidekiq.logger).to receive(:error).with(/Knowledge Quiz error during main quiz execution/)
        
        worker.perform
      end

      it 'still releases the lock' do
        expect(quiz_session).to receive(:unlock_quiz)
        
        worker.perform
      end

      it 'does not proceed to main execution' do
        expect(worker).not_to receive(:run_quiz_questions)
        
        worker.perform
      end
    end

    context 'when errors occur during main execution' do
      before do
        allow(quiz_session).to receive(:cleanup_quiz_data).and_raise(Redis::BaseError.new("Redis connection failed"))
      end

      it 'handles errors and marks quiz as failed' do
        expect(Sidekiq.logger).to receive(:error).with(/Knowledge Quiz error during main quiz execution/)
        expect(quiz_session).to receive(:set_quiz_status).with("Failed", hash_including(:error_time))
        
        worker.perform
      end

      it 'still cleans up resources' do
        expect(quiz_session).to receive(:set_quiz_status).with("Available")
        expect(quiz_session).to receive(:unlock_quiz)
        
        worker.perform
      end
    end

    context 'when no quiz questions are available' do
      before do
        # Return nil when no questions are found
        allow(QuizQuestion).to receive_message_chain(:mcq, :approved, :order, :first).and_return(nil)
      end

      it 'continues quiz execution without questions' do
        expect(Sidekiq.logger).to receive(:error).with(/No approved MCQ questions found/).at_least(:once)
        expect(Sidekiq.logger).to receive(:info).with(/Knowledge Quiz completed successfully/)
        
        worker.perform
      end
    end

    context 'with quiz questions available' do
      before do
        allow(QuizQuestion).to receive_message_chain(:mcq, :approved, :order, :first).and_return(question)
      end

      it 'publishes questions to PubNub' do
        expect(PN).to receive(:publish).with(
          hash_including(
            channel: "quiz-1",
            message: hash_including(
              meta: "question",
              q_id: 123,
              q_type: "mcq",
              mc_question: "Test?",
              mc_answer: "A",
              time_alloc: 30
            )
          )
        ).at_least(:once)
        
        worker.perform
      end

      it 'updates question statistics' do
        expect(quiz_session).to receive(:update_question_stats).at_least(:once)
        expect(question).to receive(:update!).with(hash_including(:last_asked))
        
        worker.perform
      end

      it 'publishes scoreboard updates' do
        expect(PN).to receive(:publish).with(
          hash_including(
            channel: "quiz-1",
            message: hash_including(meta: "scoreboard")
          )
        ).at_least(:once)
        
        worker.perform
      end
    end
  end

  describe 'concurrency protection and idempotency' do
    describe 'lock management' do
      before do
        # Initialize the @quiz_session instance variable for direct method testing
        worker.instance_variable_set(:@quiz_session, quiz_session)
      end

      it 'delegates lock acquisition to QuizSession' do
        expect(quiz_session).to receive(:lock_quiz).with(KnowledgeQuiz::LOCK_TIMEOUT)
        
        worker.send(:acquire_quiz_lock)
      end

      it 'delegates lock release to QuizSession' do
        expect(quiz_session).to receive(:unlock_quiz)
        
        worker.send(:release_quiz_lock)
      end

      it 'checks quiz status through QuizSession' do
        expect(quiz_session).to receive(:quiz_in_progress?)
        
        worker.send(:quiz_in_progress?)
      end
    end

    describe 'concurrent execution prevention' do
      context 'when another worker holds the lock' do
        before do
          allow(quiz_session).to receive(:lock_quiz).and_return(false)
        end

        it 'prevents duplicate quiz execution' do
          expect(worker).not_to receive(:setup_quiz_environment)
          expect(Sidekiq.logger).to receive(:warn).with(/already running, aborting/)
          
          worker.perform
        end
      end

      context 'when quiz is already in progress' do
        before do
          allow(quiz_session).to receive(:quiz_in_progress?).and_return(true)
        end

        it 'prevents duplicate quiz execution' do
          expect(worker).not_to receive(:setup_quiz_environment)
          expect(Sidekiq.logger).to receive(:warn).with(/already in progress, aborting/)
          
          worker.perform
        end
      end
    end
  end

  describe 'error handling and retry logic' do
    describe '#with_retry' do
      before do
        # Allow sleep for retry tests
        allow(worker).to receive(:sleep).and_call_original
      end

      it 'succeeds on first attempt' do
        counter = 0
        
        worker.send(:with_retry, "test operation") do
          counter += 1
        end
        
        expect(counter).to eq(1)
      end

      it 'retries on failure with exponential backoff' do
        attempts = 0
        
        expect(worker).to receive(:sleep).with(2).once
        expect(worker).to receive(:sleep).with(4).once
        
        expect {
          worker.send(:with_retry, "test operation") do
            attempts += 1
            raise StandardError.new("Test error") if attempts < 3
          end
        }.not_to raise_error
        
        expect(attempts).to eq(3)
      end

      it 'fails after max retries and logs warnings' do
        expect(Sidekiq.logger).to receive(:warn).with(/test operation failed/).exactly(3).times
        expect(Sidekiq.logger).to receive(:error).with(/test operation failed after 3 attempts/)
        
        expect {
          worker.send(:with_retry, "test operation") do
            raise StandardError.new("Persistent error")
          end
        }.to raise_error(StandardError, "Persistent error")
      end
    end

    describe '#publish_with_retry' do
      before do
        allow(worker).to receive(:sleep).and_call_original
      end

      it 'succeeds on first attempt' do
        expect(PN).to receive(:publish).once
        
        worker.send(:publish_with_retry, "quiz-1", {test: "message"})
      end

      it 'retries PubNub failures with exponential backoff' do
        call_count = 0
        allow(PN).to receive(:publish) do
          call_count += 1
          raise StandardError.new("Network timeout") if call_count < 3
          true
        end
        
        expect(worker).to receive(:sleep).with(2).once
        expect(worker).to receive(:sleep).with(4).once
        expect(Sidekiq.logger).to receive(:warn).with(/PubNub publish failed/).twice
        
        worker.send(:publish_with_retry, "quiz-1", {test: "message"})
      end

      it 'fails after max retries' do
        allow(PN).to receive(:publish).and_raise(StandardError.new("Persistent network error"))
        
        expect(Sidekiq.logger).to receive(:error).with(/PubNub publish failed after 3 attempts/)
        
        expect {
          worker.send(:publish_with_retry, "quiz-1", {test: "message"})
        }.to raise_error(StandardError, "Persistent network error")
      end
    end

    describe '#handle_quiz_error' do
      let(:error) { StandardError.new("Test error") }
      let(:backtrace) { ["line1", "line2", "line3"] }

      before do
        allow(error).to receive(:backtrace).and_return(backtrace)
      end

      it 'logs error details with context and backtrace' do
        expect(Sidekiq.logger).to receive(:error).with(/Knowledge Quiz error during test context.*Test error/)
        expect(Sidekiq.logger).to receive(:error).with(backtrace.join("\n"))
        
        worker.send(:handle_quiz_error, "test context", error)
      end

      it 'notifies participants when channel is provided' do
        channel = "quiz-1"
        
        expect(PN).to receive(:publish).with(
          hash_including(
            channel: channel,
            message: hash_including(
              meta: "error",
              message: "Quiz experienced technical difficulties and has been stopped."
            ),
            http_sync: true,
            callback: PN_CALLBACK
          )
        )
        
        worker.send(:handle_quiz_error, "test context", error, channel)
      end

      it 'handles notification failures gracefully' do
        channel = "quiz-1"
        allow(PN).to receive(:publish).and_raise(StandardError.new("Network error"))
        
        expect(Sidekiq.logger).to receive(:error).with(/Failed to notify participants of error.*Network error/)
        
        worker.send(:handle_quiz_error, "test context", error, channel)
      end

      it 'does not attempt notification without channel' do
        expect(PN).not_to receive(:publish)
        
        worker.send(:handle_quiz_error, "test context", error)
      end
    end
  end

  describe 'timezone and scheduling' do
    describe '#calculate_next_quiz_time' do
      it 'uses UTC for scheduling calculations' do
        travel_to Time.parse("2025-01-01 12:00:00 EST") do
          # Remove the IceCube mock for this test to test actual scheduling
          allow(IceCube::Schedule).to receive(:new).and_call_original
          
          next_time = worker.send(:calculate_next_quiz_time)
          
          # Should be either next Wednesday 9 AM or Saturday 3 PM
          expect([3, 6]).to include(next_time.wday) # Wednesday = 3, Saturday = 6
          expect([9, 15]).to include(next_time.hour) # 9 AM or 3 PM UTC
          expect(next_time.zone).to eq("UTC")
        end
      end

      it 'calculates Wednesday 9 AM UTC schedule' do
        travel_to Time.parse("2025-01-06 10:00:00 UTC") do # Monday
          # Remove the IceCube mock for this test to test actual scheduling
          allow(IceCube::Schedule).to receive(:new).and_call_original
          
          next_time = worker.send(:calculate_next_quiz_time)
          
          expect(next_time.wday).to eq(3) # Wednesday
          expect(next_time.hour).to eq(9)
          expect(next_time.min).to eq(0)
          expect(next_time.sec).to eq(0)
        end
      end

      it 'calculates Saturday 3 PM UTC schedule' do
        travel_to Time.parse("2025-01-09 16:00:00 UTC") do # Thursday after Wednesday quiz
          # Remove the IceCube mock for this test to test actual scheduling
          allow(IceCube::Schedule).to receive(:new).and_call_original
          
          next_time = worker.send(:calculate_next_quiz_time)
          
          expect(next_time.wday).to eq(6) # Saturday
          expect(next_time.hour).to eq(15)
          expect(next_time.min).to eq(0)
          expect(next_time.sec).to eq(0)
        end
      end
    end

    it 'stores UTC timestamps in quiz status' do
      travel_to Time.parse("2025-01-01 12:00:00 EST") do
        expected_time = Time.current.utc.iso8601
        
        expect(quiz_session).to receive(:set_quiz_status).with(
          "In progress. Initializing...", 
          hash_including(start_time: expected_time)
        )
        
        worker.perform
      end
    end

    it 'handles timezone conversion correctly across different local zones' do
      # Test in different timezone
      ENV['TZ'] = 'Asia/Tokyo'
      Time.zone = 'Asia/Tokyo'
      
      travel_to Time.parse("2025-01-01 21:00:00 +0900") do # 12:00 UTC
        # Remove the IceCube mock for this test to test actual scheduling
        allow(IceCube::Schedule).to receive(:new).and_call_original
        
        next_time = worker.send(:calculate_next_quiz_time)
        
        # Should still be in UTC regardless of local timezone
        expect(next_time.zone).to eq("UTC")
        expect([3, 6]).to include(next_time.wday)
        expect([9, 15]).to include(next_time.hour)
      end
      
      # Reset timezone
      ENV['TZ'] = 'UTC'
      Time.zone = 'UTC'
    end
  end

  describe 'health monitoring and metrics' do
    it 'records success metrics with duration and count' do
      start_time = Time.current.utc
      end_time = start_time + 30.seconds
      
      travel_to start_time do
        # Stub the internal timing to simulate 30 seconds duration
        allow(Time).to receive(:current).and_return(start_time, end_time)
        
        expect(quiz_session).to receive(:set_quiz_status).with(
          "Available",
          hash_including(
            last_success: kind_of(String),
            duration_seconds: be_within(1).of(30),
            success_count: 6 # 5 + 1
          )
        )
        
        worker.perform
      end
    end

    it 'tracks quiz performance over time' do
      allow(quiz_session).to receive(:get_quiz_metadata).and_return({"success_count" => "10"})
      
      expect(quiz_session).to receive(:set_quiz_status).with(
        "Available",
        hash_including(success_count: 11)
      )
      
      worker.perform
    end

    it 'handles missing metadata gracefully' do
      allow(quiz_session).to receive(:get_quiz_metadata).and_return({})
      
      expect(quiz_session).to receive(:set_quiz_status).with(
        "Available",
        hash_including(success_count: 1) # 0 + 1
      )
      
      worker.perform
    end
  end

  describe 'resource cleanup' do
    it 'always cleans up resources on success' do
      expect(quiz_session).to receive(:set_quiz_status).with("Available")
      expect(quiz_session).to receive(:unlock_quiz)
      
      worker.perform
    end

    it 'always cleans up resources on failure' do
      allow(quiz_session).to receive(:cleanup_quiz_data).and_raise(StandardError.new("Redis error"))
      
      expect(quiz_session).to receive(:set_quiz_status).with("Available")
      expect(quiz_session).to receive(:unlock_quiz)
      
      worker.perform
    end

    it 'always cleans up resources even when cleanup fails' do
      allow(quiz_session).to receive(:set_quiz_status).with("Available").and_raise(StandardError.new("Final cleanup error"))
      
      expect(quiz_session).to receive(:unlock_quiz)
      
      worker.perform
    end
  end

  describe 'question difficulty updates' do
    let(:question_stats) do
      [
        {'qq_id' => '123', 'answered' => '5', 'total_score' => '35'},
        {'qq_id' => '124', 'answered' => '3', 'total_score' => '15'}
      ]
    end

    before do
      allow(quiz_session).to receive(:get_question_stats).and_return(question_stats)
      allow(QuizQuestion).to receive(:find).with(123).and_return(question)
      allow(QuizQuestion).to receive(:find).with(124).and_return(question)
    end

    it 'updates question difficulty based on performance' do
      expect(question).to receive(:update_difficulty).with(5, 70.0) # (35/5)*10
      expect(question).to receive(:update_difficulty).with(3, 50.0) # (15/3)*10
      
      worker.perform
    end

    it 'handles missing questions gracefully' do
      allow(QuizQuestion).to receive(:find).with(123).and_raise(ActiveRecord::RecordNotFound)
      
      expect(Sidekiq.logger).to receive(:error).with(/Question 123 not found/)
      
      worker.perform
    end

    it 'calculates percentage correctly for zero answers' do
      question_stats[0]['answered'] = '0'
      
      expect(question).to receive(:update_difficulty).with(0, 0)
      
      worker.perform
    end

    describe 'scoring calculation from quiz scores out of 10' do
      it 'correctly converts scores out of 10 to percentages' do
        # Test different scoring scenarios
        test_cases = [
          { 'qq_id' => '201', 'answered' => '5', 'total_score' => '50' },  # All perfect scores: 50/5*10 = 100%
          { 'qq_id' => '202', 'answered' => '4', 'total_score' => '28' },  # Mixed scores: 28/4*10 = 70%
          { 'qq_id' => '203', 'answered' => '10', 'total_score' => '56' }, # Many answers: 56/10*10 = 56%
          { 'qq_id' => '204', 'answered' => '2', 'total_score' => '5' }    # Low scores: 5/2*10 = 25%
        ]
        
        allow(quiz_session).to receive(:get_question_stats).and_return(test_cases)
        
        test_cases.each do |stat|
          q_id = stat['qq_id'].to_i
          test_question = instance_double(QuizQuestion)
          allow(QuizQuestion).to receive(:find).with(q_id).and_return(test_question)
          allow(test_question).to receive(:update_difficulty)
        end
        
        worker.perform
        
        # Verify each percentage calculation
        expect(QuizQuestion.find(201)).to have_received(:update_difficulty).with(5, 100.0)
        expect(QuizQuestion.find(202)).to have_received(:update_difficulty).with(4, 70.0)
        expect(QuizQuestion.find(203)).to have_received(:update_difficulty).with(10, 56.0)
        expect(QuizQuestion.find(204)).to have_received(:update_difficulty).with(2, 25.0)
      end

      it 'handles partial credit scores correctly' do
        # Scenario: Question with scores like 7/10, 5/10, 3/10, 9/10
        # Total: 24 out of 40 possible = 60%
        question_stats = [
          { 'qq_id' => '300', 'answered' => '4', 'total_score' => '24' }
        ]
        
        test_question = instance_double(QuizQuestion)
        allow(quiz_session).to receive(:get_question_stats).and_return(question_stats)
        allow(QuizQuestion).to receive(:find).with(300).and_return(test_question)
        allow(test_question).to receive(:update_difficulty)
        
        worker.perform
        
        expect(test_question).to have_received(:update_difficulty).with(4, 60.0)
      end
    end
  end

  describe 'winner announcement' do
    let(:scoreboard) do
      [
        {'name' => 'John Doe', 'id' => '100', 'score' => '85'},
        {'name' => 'Jane Smith', 'id' => '101', 'score' => '70'}
      ]
    end

    before do
      allow(quiz_session).to receive(:get_scoreboard).and_return(scoreboard)
    end

    it 'announces winner when participants exist' do
      expect(Tweet).to receive(:create!).with(
        news: "John Doe won the Bible knowledge quiz",
        user_id: "100",
        importance: 2
      )
      
      worker.perform
    end

    it 'does not announce winner when no participants' do
      allow(quiz_session).to receive(:get_scoreboard).and_return([])
      
      # Should still create the initial announcement tweet, but not the winner tweet
      expect(Tweet).to receive(:create!).with(
        news: "The Bible knowledge quiz is starting. <a href=\"live_quiz\">Join now!</a>",
        user_id: 1,
        importance: 2
      )
      expect(Tweet).not_to receive(:create!).with(hash_including(news: /won/))
      
      worker.perform
    end
  end

  describe 'Redis connection failure scenarios' do
    it 'handles Redis connection errors during chat operations' do
      allow($redis).to receive(:hset).and_raise(Redis::ConnectionError.new("Connection lost"))
      
      expect(Sidekiq.logger).to receive(:error).with(/main quiz execution/)
      
      worker.perform
    end

    it 'handles Redis timeout errors' do
      allow($redis).to receive(:exists).and_raise(Redis::TimeoutError.new("Operation timeout"))
      
      expect(Sidekiq.logger).to receive(:error).with(/main quiz execution/)
      
      worker.perform
    end
  end

  describe 'PubNub failure scenarios' do
    context 'when PubNub is completely unavailable' do
      before do
        allow(PN).to receive(:publish).and_raise(StandardError.new("PubNub service unavailable"))
      end

      it 'fails gracefully after retries' do
        expect(Sidekiq.logger).to receive(:error).with(/PubNub publish failed after 3 attempts/)
        expect(Sidekiq.logger).to receive(:error).with(/main quiz execution/)
        
        worker.perform
      end
    end

    context 'when PubNub times out intermittently' do
      before do
        call_count = 0
        allow(PN).to receive(:publish) do
          call_count += 1
          if call_count.odd?
            raise Timeout::Error.new("Request timeout")
          end
          true
        end
      end

      it 'retries and eventually succeeds' do
        expect(Sidekiq.logger).to receive(:warn).with(/PubNub publish failed/).at_least(:once)
        expect(Sidekiq.logger).to receive(:info).with(/Knowledge Quiz completed successfully/)
        
        worker.perform
      end
    end
  end

  describe 'environment-specific behavior' do
    context 'in production environment' do
      before do
        allow(Rails.env).to receive(:production?).and_return(true)
      end

      it 'uses production timing for chat and waiting periods' do
        expect(worker).to receive(:sleep).with(300) # 5 minutes chat
        expect(worker).to receive(:sleep).with(600) # 10 minutes post-quiz
        
        worker.perform
      end

      it 'runs 25 questions in production' do
        allow(QuizQuestion).to receive_message_chain(:mcq, :approved, :order, :first).and_return(question)
        
        expect(PN).to receive(:publish).with(hash_including(message: hash_including(meta: "question"))).exactly(25).times
        
        worker.perform
      end
    end

    context 'in test/development environment' do
      before do
        allow(Rails.env).to receive(:production?).and_return(false)
      end

      it 'uses shorter timing for testing' do
        expect(worker).to receive(:sleep).with(30).twice # Chat and post-quiz periods
        
        worker.perform
      end

      it 'runs only 3 questions in non-production' do
        allow(QuizQuestion).to receive_message_chain(:mcq, :approved, :order, :first).and_return(question)
        
        expect(PN).to receive(:publish).with(hash_including(message: hash_including(meta: "question"))).exactly(3).times
        
        worker.perform
      end
    end
  end
end