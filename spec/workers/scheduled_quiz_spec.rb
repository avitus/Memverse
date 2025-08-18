require 'spec_helper'

describe ScheduledQuiz do

  let(:worker) { described_class.new }
  let(:user) { User.create!(name: "Test User", email: "test@example.com", password: "password", password_confirmation: "password") }
  let(:quiz) { Quiz.create!(id: 2, name: "Test Quiz", user: user, start_time: 30.seconds.from_now.utc) }

  before do
    # Mock Redis for testing
    allow($redis).to receive(:set).and_return(true)
    allow($redis).to receive(:del).and_return(true)
    allow($redis).to receive(:hset).and_return(true)
    allow($redis).to receive(:hget).and_return(nil)
    allow($redis).to receive(:hmget).and_return([nil])
    allow($redis).to receive(:exists).and_return(false)
    allow($redis).to receive(:keys).and_return([])
    allow($redis).to receive(:hgetall).and_return({})
    allow($redis).to receive(:pipelined).and_yield($redis)

    # Mock PubNub to avoid network calls
    allow(PN).to receive(:publish).and_return(true)

    # Mock Tweet creation
    allow(Tweet).to receive(:create!).and_return(true)

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
    context 'when no quiz is scheduled' do
      before do
        Quiz.destroy_all
      end

      it 'returns early without error' do
        expect(Sidekiq.logger).to receive(:debug).with(/No scheduled quiz found/)
        
        worker.perform
      end

      it 'does not acquire any locks' do
        expect($redis).not_to receive(:set).with(/scheduled_quiz_lock/, anything, anything)
        
        worker.perform
      end
    end

    context 'when quiz has no questions' do
      before do
        quiz # Create quiz but no questions
      end

      it 'skips quiz and logs warning' do
        expect(Sidekiq.logger).to receive(:warn).with(/Quiz ##{quiz.id} has no questions, skipping/)
        
        worker.perform
      end

      it 'does not proceed with quiz execution' do
        expect(worker).not_to receive(:execute_quiz)
        
        worker.perform
      end
    end

    context 'when quiz is the knowledge quiz (ID=1)' do
      before do
        quiz_1 = Quiz.create!(id: 1, name: "Knowledge Quiz", user: user, start_time: 30.seconds.from_now.utc)
        # Add a question so the quiz will be found
        QuizQuestion.create!(
          quiz: quiz_1,
          question_no: 1,
          question_type: "mcq",
          mc_question: "What is the first word of John 1:1?",
          mc_option_a: "In",
          mc_option_b: "The", 
          mc_option_c: "Beginning",
          mc_option_d: "Word",
          mc_answer: "A",
          supporting_ref: Uberverse.create!(book: "John", chapter: 1, versenum: 1),
          times_answered: 10,
          perc_correct: 50
        )
      end

      it 'skips quiz handled by different worker' do
        expect(Sidekiq.logger).to receive(:debug).with(/Quiz #1 is the Wed\/Sat quiz/)
        
        worker.perform
      end
    end

    context 'when valid quiz is found with questions' do
      let(:uberverse) { Uberverse.create!(book: "John", chapter: 1, versenum: 1) }
      let(:quiz_question) do
        QuizQuestion.create!(
          quiz: quiz,
          question_no: 1,
          question_type: "mcq",
          mc_question: "Test question?",
          mc_option_a: "A",
          mc_option_b: "B", 
          mc_option_c: "C",
          mc_option_d: "D",
          mc_answer: "A",
          supporting_ref: uberverse,
          times_answered: 10,
          perc_correct: 50
        )
      end

      before do
        quiz_question # Create quiz with questions
        # Mock the Quiz.where to return our quiz
        allow(Quiz).to receive(:where).and_return(double("relation", first: quiz))
      end

      it 'completes the quiz workflow successfully' do
        # Just test that it doesn't raise an error and completes
        expect { worker.perform }.not_to raise_error
      end

      it 'acquires and releases quiz lock' do
        # QuizSession now handles the locking with different key format
        lock_key = "quiz_session:#{quiz.id}:lock"
        
        expect($redis).to receive(:set).with(lock_key, Process.pid, nx: true, ex: 3600).and_return(true)
        expect($redis).to receive(:del).with(lock_key)
        
        worker.perform
      end

      it 'initializes quiz with proper status' do
        # QuizSession uses different key format for status
        status_key = "quiz_session:#{quiz.id}:status"
        
        expect($redis).to receive(:hset).with(status_key, "status", "In progress. Chat opening soon.")
        expect($redis).to receive(:hset).with(status_key, "updated_at", anything)
        expect($redis).to receive(:hset).with(status_key, "start_time", anything)
        expect($redis).to receive(:hset).with(status_key, "quiz_id", quiz.id.to_s)
        
        worker.perform
      end

      it 'announces quiz start' do
        expect(Tweet).to receive(:create!).with(
          news: "#{quiz.name} is starting. <a href=\"live_quiz/#{quiz.id}\">Join now!</a>",
          user_id: 1,
          importance: 2
        )
        
        worker.perform
      end

      it 'publishes quiz questions to PubNub' do
        expect(PN).to receive(:publish).with(
          hash_including(
            channel: "quiz-#{quiz.id}",
            message: hash_including(
              meta: "question",
              q_id: quiz_question.id,
              q_num: 1,
              q_type: "mcq"
            )
          )
        ).at_least(:once)
        
        worker.perform
      end

      it 'opens and closes chat channels' do
        channel = "quiz-#{quiz.id}"
        
        # Should open chat
        expect($redis).to receive(:hset).with("chat-#{channel}", "status", "Open")
        expect(PN).to receive(:publish).with(
          hash_including(
            message: hash_including(meta: "chat_status", status: "Open")
          )
        )
        
        # Should close chat
        expect($redis).to receive(:hset).with("chat-#{channel}", "status", "Closed")
        expect(PN).to receive(:publish).with(
          hash_including(
            message: hash_including(meta: "chat_status", status: "Closed")
          )
        )
        
        worker.perform
      end

      it 'records success metrics' do
        # QuizSession uses different key format for status
        status_key = "quiz_session:#{quiz.id}:status"
        
        expect($redis).to receive(:hset).with(status_key, "last_success", anything)
        expect($redis).to receive(:hset).with(status_key, "duration_seconds", anything)
        expect($redis).to receive(:hset).with(status_key, "success_count", anything)
        
        worker.perform
      end
    end

    context 'when quiz is already in progress' do
      before do
        quiz
        # Add a question so it will be found by find_scheduled_quiz
        QuizQuestion.create!(
          quiz: quiz,
          question_no: 1,
          question_type: "mcq",
          mc_question: "What is the first word of John 1:1?",
          mc_option_a: "In",
          mc_option_b: "The", 
          mc_option_c: "Beginning",
          mc_option_d: "Word",
          mc_answer: "A",
          supporting_ref: Uberverse.create!(book: "John", chapter: 1, versenum: 1),
          times_answered: 10,
          perc_correct: 50
        )
        # Mock Quiz.where to return our quiz
        allow(Quiz).to receive(:where).and_return(double("relation", first: quiz))
        # Mock QuizSession to indicate quiz is in progress
        status_key = "quiz_session:#{quiz.id}:status"
        allow($redis).to receive(:hget).with(status_key, "status").and_return("In progress. Wait for question.")
      end

      it 'aborts execution gracefully' do
        expect(Sidekiq.logger).to receive(:warn).with(/Quiz ##{quiz.id} : Already in progress, aborting/)
        
        worker.perform
      end

      it 'does not execute main quiz logic' do
        expect(worker).not_to receive(:execute_quiz)
        
        worker.perform
      end
    end

    context 'when lock cannot be acquired' do
      before do
        quiz
        # Add a question so it will be found by find_scheduled_quiz
        QuizQuestion.create!(
          quiz: quiz,
          question_no: 1,
          question_type: "mcq",
          mc_question: "What is the first word of John 1:1?",
          mc_option_a: "In",
          mc_option_b: "The", 
          mc_option_c: "Beginning",
          mc_option_d: "Word",
          mc_answer: "A",
          supporting_ref: Uberverse.create!(book: "John", chapter: 1, versenum: 1),
          times_answered: 10,
          perc_correct: 50
        )
        # Mock Quiz.where to return our quiz
        allow(Quiz).to receive(:where).and_return(double("relation", first: quiz))
        # Mock lock acquisition to fail
        allow($redis).to receive(:set).and_return(false)
      end

      it 'aborts execution gracefully' do
        expect(Sidekiq.logger).to receive(:warn).with(/Quiz ##{quiz.id} : Already running, aborting/)
        
        worker.perform
      end
    end

    context 'when database errors occur' do
      before do
        allow(Quiz).to receive(:where).and_raise(ActiveRecord::ConnectionTimeoutError.new("Database timeout"))
      end

      it 'handles errors gracefully' do
        expect(Sidekiq.logger).to receive(:error).with(/ScheduledQuiz error during quiz initialization/)
        
        worker.perform
      end
    end

    context 'when PubNub fails' do
      before do
        quiz
        # Mock Quiz.where to return our quiz
        allow(Quiz).to receive(:where).and_return(double("relation", first: quiz))
        # Add a question so quiz execution proceeds
        QuizQuestion.create!(
          quiz: quiz,
          question_no: 1,
          question_type: "mcq",
          mc_question: "What is the first word of John 1:1?",
          mc_option_a: "In",
          mc_option_b: "The", 
          mc_option_c: "Beginning",
          mc_option_d: "Word",
          mc_answer: "A",
          supporting_ref: Uberverse.create!(book: "John", chapter: 1, versenum: 1),
          times_answered: 10,
          perc_correct: 50
        )
        
        # Make PubNub fail
        allow(PN).to receive(:publish).and_raise(StandardError.new("Network timeout"))
      end

      it 'retries PubNub operations' do
        expect(Sidekiq.logger).to receive(:warn).with(/PubNub publish failed/).at_least(:once)
        expect(worker).to receive(:sleep).at_least(:once)
        
        worker.perform
      end
    end
  end

  describe '#find_scheduled_quiz' do
    before do
      # Ensure quiz has questions for these tests
      QuizQuestion.create!(
        quiz: quiz,
        question_no: 1,
        question_type: "mcq",
        mc_question: "What is the first word of John 1:1?",
        mc_option_a: "In",
        mc_option_b: "The", 
        mc_option_c: "Beginning",
        mc_option_d: "Word",
        mc_answer: "A",
        supporting_ref: Uberverse.create!(book: "John", chapter: 1, versenum: 1),
        times_answered: 10,
        perc_correct: 50
      )
    end

    it 'finds quiz starting within next minute' do
      travel_to quiz.start_time - 30.seconds do
        found_quiz = worker.send(:find_scheduled_quiz)
        expect(found_quiz).to eq(quiz)
      end
    end

    it 'does not find quiz starting too far in future' do
      travel_to quiz.start_time - 2.minutes do
        found_quiz = worker.send(:find_scheduled_quiz)
        expect(found_quiz).to be_nil
      end
    end

    it 'does not find quiz that already started' do
      travel_to quiz.start_time + 2.minutes do
        found_quiz = worker.send(:find_scheduled_quiz)
        expect(found_quiz).to be_nil
      end
    end

    it 'uses UTC for time comparisons' do
      # Test with different local timezone
      travel_to Time.parse("2025-01-01 12:00:00 EST") do
        quiz.update!(start_time: 30.seconds.from_now.utc)
        
        found_quiz = worker.send(:find_scheduled_quiz)
        expect(found_quiz).to eq(quiz)
      end
    end
  end

  describe 'question type handling' do
    let(:uberverse) { Uberverse.create!(book: "John", chapter: 1, versenum: 1) }

    before do
      quiz
    end

    context 'with recitation questions' do
      let(:recitation_question) do
        QuizQuestion.create!(
          quiz: quiz,
          question_no: 1,
          question_type: "recitation",
          passage: "John 1:1",
          supporting_ref: uberverse,
          times_answered: 10,
          perc_correct: 50
        )
      end

      before do
        recitation_question
        # Mock Quiz.where to return our quiz
        allow(Quiz).to receive(:where).and_return(double("relation", first: quiz))
        # Mock the passage_translations method on any instance of QuizQuestion
        allow_any_instance_of(QuizQuestion).to receive(:passage_translations).and_return({"ESV" => "In the beginning was the Word"})
      end

      it 'calculates time allocation correctly' do
        word_count = "In the beginning was the Word".split(" ").length
        expected_time = (word_count * 2.5 + 15.0).to_i
        
        expect(PN).to receive(:publish).with(
          hash_including(
            message: hash_including(
              q_type: "recitation",
              time_alloc: expected_time
            )
          )
        ).at_least(:once)
        
        worker.perform
      end
    end

    context 'with reference questions' do
      before do
        QuizQuestion.create!(
          quiz: quiz,
          question_no: 1,
          question_type: "reference",
          supporting_ref: uberverse,
          times_answered: 10,
          perc_correct: 50
        )
        # Mock Quiz.where to return our quiz
        allow(Quiz).to receive(:where).and_return(double("relation", first: quiz))
      end

      it 'uses standard time allocation' do
        expect(PN).to receive(:publish).with(
          hash_including(
            message: hash_including(
              q_type: "reference",
              time_alloc: 25
            )
          )
        ).at_least(:once)
        
        worker.perform
      end
    end

    context 'with unknown question types' do
      before do
        QuizQuestion.create!(
          quiz: quiz,
          question_no: 1,
          question_type: "unknown_type",
          supporting_ref: uberverse,
          times_answered: 10,
          perc_correct: 50
        )
        # Mock Quiz.where to return our quiz
        allow(Quiz).to receive(:where).and_return(double("relation", first: quiz))
      end

      it 'logs warning and continues' do
        expect(Sidekiq.logger).to receive(:warn).with(/Unknown question type: unknown_type/)
        
        worker.perform
      end
    end
  end

  describe 'error handling and retry logic' do
    describe '#with_retry' do
      it 'succeeds on first attempt' do
        counter = 0
        
        worker.send(:with_retry, "test operation", 999) do
          counter += 1
        end
        
        expect(counter).to eq(1)
      end

      it 'retries on failure with exponential backoff' do
        attempts = 0
        
        expect(worker).to receive(:sleep).with(2).once
        expect(worker).to receive(:sleep).with(4).once
        
        expect {
          worker.send(:with_retry, "test operation", 999) do
            attempts += 1
            raise StandardError.new("Test error") if attempts < 3
          end
        }.not_to raise_error
        
        expect(attempts).to eq(3)
      end

      it 'fails after max retries' do
        expect {
          worker.send(:with_retry, "test operation", 999) do
            raise StandardError.new("Persistent error")
          end
        }.to raise_error(StandardError, "Persistent error")
      end
    end
  end

  describe 'resource cleanup' do
    before do
      quiz
      # Add a question so the quiz will be found
      QuizQuestion.create!(
        quiz: quiz,
        question_no: 1,
        question_type: "mcq",
        mc_question: "What is the first word of John 1:1?",
        mc_option_a: "In",
        mc_option_b: "The", 
        mc_option_c: "Beginning",
        mc_option_d: "Word",
        mc_answer: "A",
        supporting_ref: Uberverse.create!(book: "John", chapter: 1, versenum: 1),
        times_answered: 10,
        perc_correct: 50
      )
      # Mock Quiz.where to return our quiz
      allow(Quiz).to receive(:where).and_return(double("relation", first: quiz))
    end

    it 'always cleans up resources' do
      status_key = "quiz_session:#{quiz.id}:status"
      lock_key = "quiz_session:#{quiz.id}:lock"
      
      expect($redis).to receive(:hset).with(status_key, "status", "Available")
      expect($redis).to receive(:del).with(lock_key).at_least(:once)
      
      worker.perform
    end

    it 'cleans up even when errors occur' do
      lock_key = "quiz_session:#{quiz.id}:lock"
      
      # Force an error during execution
      allow(PN).to receive(:publish).and_raise(StandardError.new("Fatal error"))
      
      expect($redis).to receive(:del).with(lock_key).at_least(:once)
      
      worker.perform
    end
  end

  describe 'concurrency protection' do
    before do
      quiz
      # Ensure quiz has questions so it will be found
      QuizQuestion.create!(
        quiz: quiz,
        question_no: 1,
        question_type: "mcq",
        mc_question: "What is the first word of John 1:1?",
        mc_option_a: "In",
        mc_option_b: "The", 
        mc_option_c: "Beginning",
        mc_option_d: "Word",
        mc_answer: "A",
        supporting_ref: Uberverse.create!(book: "John", chapter: 1, versenum: 1),
        times_answered: 10,
        perc_correct: 50
      )
      # Mock Quiz.where to return our quiz
      allow(Quiz).to receive(:where).and_return(double("relation", first: quiz))
    end

    it 'prevents multiple workers from running same quiz' do
      # Simulate another worker already has the lock
      allow($redis).to receive(:set).with(
        "quiz_session:#{quiz.id}:lock", 
        anything, 
        anything
      ).and_return(false)
      
      expect(Sidekiq.logger).to receive(:warn).with(/Already running, aborting/)
      
      worker.perform
    end
  end
end