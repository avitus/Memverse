require 'spec_helper'

describe ScheduledQuiz do # skipcq: RB-R1001 (one example group covers the whole quiz run)

  let(:worker) { described_class.new }
  let(:user) { User.create!(name: "Test User", email: "test@example.com", password: "password", password_confirmation: "password") }
  let(:quiz) { Quiz.create!(id: 2, name: "Test Quiz", user: user, start_time: 30.seconds.from_now.utc) }
  
  # Helper method to properly mock Quiz queries
  def mock_quiz_queries(quiz)
    relation = double("relation")
    allow(Quiz).to receive(:where) do |*args|
      if args.length >= 1 && args[0].is_a?(String) && args[0].include?("start_time")
        # This is the time-based query for finding scheduled quiz
        double("time_relation", first: quiz)
      else
        # This is for other queries
        relation
      end
    end
    allow(relation).to receive(:not).with(id: 1).and_return(relation)
    allow(relation).to receive(:order).with(start_time: :asc).and_return(relation)
    allow(relation).to receive(:limit).with(5).and_return(relation)
    allow(relation).to receive(:each).and_yield(quiz) if quiz
    allow(relation).to receive(:joins).and_return(relation)
    allow(relation).to receive(:distinct).and_return(relation)
    allow(relation).to receive(:first).and_return(quiz)
    relation
  end

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
    pubnub_response = double("PubNub Response", timetoken: 1234567890, status: 200)
    allow(PN).to receive(:publish).and_return(pubnub_response)

    # Mock Tweet creation
    allow(Tweet).to receive(:create!).and_return(true)

    # Mock sleep to speed up tests - allow any sleep call
    allow(worker).to receive(:sleep).and_return(nil)

    # Mock Rails environment  
    allow(Rails.env).to receive(:production?).and_return(false)
    
    # Disable actual logging output in tests
    allow(Sidekiq.logger).to receive(:info)
    # Don't stub :warn here - let individual tests set expectations
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
        # Stub warn to avoid unmet expectations
        allow(Sidekiq.logger).to receive(:warn)

        worker.perform
      end

      it 'does not acquire any locks' do
        expect($redis).not_to receive(:set).with(/scheduled_quiz_lock/, anything, anything)
        # Stub warn to avoid unmet expectations
        allow(Sidekiq.logger).to receive(:warn)

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
        # Stub warn to avoid unmet expectations
        allow(Sidekiq.logger).to receive(:warn)

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
        # Stub warn to avoid unmet expectations
        allow(Sidekiq.logger).to receive(:warn)

        worker.perform
      end
    end

    context 'when an admin requests a quiz by id' do
      let(:uberverse) { Uberverse.create!(book: "John", chapter: 1, versenum: 1) }
      let!(:quiz_question) do
        QuizQuestion.create!(quiz: quiz, question_no: 1, question_type: "mcq", mc_question: "Test question?",
                             mc_option_a: "A", mc_option_b: "B", mc_option_c: "C", mc_option_d: "D", mc_answer: "A",
                             supporting_ref: uberverse, times_answered: 10, perc_correct: 50)
      end

      before { allow(Sidekiq.logger).to receive(:warn) }

      it 'runs that quiz even when its start time has already passed, without searching the window' do
        quiz.update!(start_time: 2.minutes.ago.utc)
        expect(worker).not_to receive(:find_scheduled_quiz)
        expect(worker).to receive(:execute_quiz).with(quiz, "quiz-#{quiz.id}", anything)

        worker.perform(quiz.id)
      end

      it 'keeps the quiz lock until the run is cleaned up, so a second job for the same quiz is rejected' do
        lock_key = QuizSession.new(quiz.id).send(:lock_key)
        lock_taken = false
        allow($redis).to receive(:set) do |key, *_args, **opts|
          if key == lock_key && opts[:nx]
            taken_before = lock_taken
            lock_taken = true
            !taken_before
          else
            true
          end
        end
        allow($redis).to receive(:exists) { |key| key == lock_key && lock_taken ? 1 : 0 }
        allow($redis).to receive(:del) do |*keys|
          lock_taken = false if keys.include?(lock_key)
          keys.size
        end

        first_run = described_class.new
        allow(first_run).to receive(:sleep)
        released_during_run = nil
        allow(first_run).to receive(:execute_quiz) do
          released_during_run = !lock_taken
          # a duplicate job arriving mid-run must neither run the quiz nor drop the lock
          second_run = described_class.new
          expect(second_run).not_to receive(:execute_quiz)
          second_run.perform(quiz.id)
          expect(lock_taken).to be(true)
        end

        first_run.perform(quiz.id)

        expect(released_during_run).to be(false)
        expect(lock_taken).to be(false) # cleanup_quiz_resources released it after the run
      end

      it 'does nothing for an id that does not exist' do
        expect(worker).not_to receive(:execute_quiz)
        worker.perform(quiz.id + 1000)
      end

      it 'leaves the knowledge quiz to KnowledgeQuiz' do
        knowledge_quiz = Quiz.create!(id: 1, name: "Knowledge", user: user, start_time: 1.minute.from_now.utc)
        expect(worker).not_to receive(:execute_quiz)
        worker.perform(knowledge_quiz.id)
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
        mock_quiz_queries(quiz)
      end

      it 'completes the quiz workflow successfully' do
        # Stub warn to avoid unmet expectations
        allow(Sidekiq.logger).to receive(:warn)

        # Just test that it doesn't raise an error and completes
        expect { worker.perform }.not_to raise_error
      end

      it 'acquires and releases quiz lock' do
        # Stub warn to avoid unmet expectations
        allow(Sidekiq.logger).to receive(:warn)

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
        # Stub warn to avoid unmet expectations
        allow(Sidekiq.logger).to receive(:warn)

        worker.perform
      end

      it 'announces quiz start' do
        expect(Tweet).to receive(:create!).with(
          news: "#{quiz.name} is starting. <a href=\"live_quiz/#{quiz.id}\">Join now!</a>",
          user_id: 1,
          importance: 2
        )
        # Stub warn to avoid unmet expectations
        allow(Sidekiq.logger).to receive(:warn)

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
        # Stub warn to avoid unmet expectations
        allow(Sidekiq.logger).to receive(:warn)

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
        # Stub warn to avoid unmet expectations
        allow(Sidekiq.logger).to receive(:warn)

        worker.perform
      end

      it 'records success metrics' do
        # QuizSession uses different key format for status
        status_key = "quiz_session:#{quiz.id}:status"
        
        expect($redis).to receive(:hset).with(status_key, "last_success", anything)
        expect($redis).to receive(:hset).with(status_key, "duration_seconds", anything)
        expect($redis).to receive(:hset).with(status_key, "success_count", anything)
        # Stub warn to avoid unmet expectations
        allow(Sidekiq.logger).to receive(:warn)

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
        # Mock Quiz queries
        mock_quiz_queries(quiz)
        # Mock QuizSession to indicate quiz is in progress with a question running
        status_key = "quiz_session:#{quiz.id}:status"
        allow($redis).to receive(:hget).with(status_key, "status").and_return("Question 1 in progress")
      end

      it 'aborts execution gracefully' do
        expect(Sidekiq.logger).to receive(:warn).with(/Quiz ##{quiz.id} : Already in progress.*aborting/)
        # Stub warn to avoid unmet expectations
        allow(Sidekiq.logger).to receive(:warn)

        worker.perform
      end

      it 'does not execute main quiz logic' do
        expect(worker).not_to receive(:execute_quiz)
        # Stub warn to avoid unmet expectations
        allow(Sidekiq.logger).to receive(:warn)

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
        # Mock Quiz queries
        mock_quiz_queries(quiz)
        # Mock lock acquisition to fail
        allow($redis).to receive(:set).and_return(false)
      end

      it 'aborts execution gracefully' do
        expect(Sidekiq.logger).to receive(:warn).with(/Quiz ##{quiz.id} : Already running.*aborting/)
        # Stub warn to avoid unmet expectations
        allow(Sidekiq.logger).to receive(:warn)

        worker.perform
      end
    end

    context 'when database errors occur' do
      before do
        allow(Quiz).to receive(:where).and_raise(ActiveRecord::ConnectionTimeoutError.new("Database timeout"))
      end

      it 'handles errors gracefully' do
        expect(Sidekiq.logger).to receive(:error).with(/ScheduledQuiz error during quiz initialization/)
        # Stub warn to avoid unmet expectations
        allow(Sidekiq.logger).to receive(:warn)

        worker.perform
      end
    end

    context 'when PubNub fails' do
      before do
        quiz
        # Mock Quiz queries
        mock_quiz_queries(quiz)
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
        # Stub warn to avoid unmet expectations
        allow(Sidekiq.logger).to receive(:warn)

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
        # Mock Quiz queries
        mock_quiz_queries(quiz)
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
        # Stub warn to avoid unmet expectations
        allow(Sidekiq.logger).to receive(:warn)

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
        # Mock Quiz queries
        mock_quiz_queries(quiz)
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
        # Stub warn to avoid unmet expectations
        allow(Sidekiq.logger).to receive(:warn)

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
        # Mock Quiz queries
        mock_quiz_queries(quiz)
      end

      it 'logs warning and continues' do
        expect(Sidekiq.logger).to receive(:warn).with(/Unknown question type: unknown_type/)
        # Stub warn to avoid unmet expectations
        allow(Sidekiq.logger).to receive(:warn)

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
      # Mock Quiz queries
      mock_quiz_queries(quiz)
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
      # Mock Quiz queries
      mock_quiz_queries(quiz)
    end

    it 'prevents multiple workers from running same quiz' do
      # Simulate another worker already has the lock
      allow($redis).to receive(:set).with(
        "quiz_session:#{quiz.id}:lock",
        anything,
        anything
      ).and_return(false)

      # The worker logs two warnings when lock fails
      expect(Sidekiq.logger).to receive(:warn).with(/Already running.*aborting/)
      expect(Sidekiq.logger).to receive(:warn).with(/Lock status:/)

      worker.perform
    end
  end

  describe 'publishing questions' do
    let(:session) { instance_double(QuizSession, open_question: true, restart_answer_window: true) }
    let(:published) { [] }
    let(:passages) { { 'NIV' => 'Jesus wept.' } }
    let(:mcq) { instance_double(QuizQuestion, id: 5, mc_question: 'Q', mc_option_a: 'a', mc_option_b: 'b', mc_option_c: 'c', mc_option_d: 'd', mc_answer: 'C') }
    let(:question) { instance_double(QuizQuestion, id: 6) }
    let(:window) { QuizSession::ANSWER_GRACE_SECONDS }

    before do
      worker.instance_variable_set(:@quiz_session, session)
      allow(worker).to receive(:publish_with_retry) { |_channel, message, _quiz_id| published << message }
    end

    def message(meta)
      published.find { |entry| entry[:meta] == meta }
    end

    it 'restarts the answer window after publishing, so that publishing takes no time from players' do
      expect(worker).to receive(:publish_with_retry).with('quiz-2', hash_including(meta: 'question'), 2).ordered
      expect(session).to receive(:restart_answer_window).with(1, 30).ordered
      expect(worker).to receive(:publish_with_retry).with('quiz-2', hash_including(meta: 'answer'), 2).ordered

      worker.send(:handle_mcq_question, mcq, 1, 'quiz-2', 2)
    end

    it 'does not publish a question that could not be opened' do
      allow(session).to receive(:open_question).and_raise(Redis::CannotConnectError)

      expect { worker.send(:handle_mcq_question, mcq, 1, 'quiz-2', 2) }.to raise_error(Redis::CannotConnectError)

      expect(published).to be_empty
    end

    it 'opens the question again if publishing it fails, while the answer is still private' do
      allow(worker).to receive(:publish_with_retry).and_invoke(
        proc { raise StandardError, 'PubNub is away' },
        proc { |_channel, msg, _quiz_id| published << msg }
      )

      worker.send(:handle_mcq_question, mcq, 1, 'quiz-2', 2)

      expect(session).to have_received(:open_question).twice
      expect(published.map { |entry| entry[:meta] }).to eq(%w[question answer])
    end

    it 'never reopens a question after publishing its answer fails' do
      allow(worker).to receive(:publish_with_retry).with(anything, hash_including(meta: 'answer'), anything).and_invoke(
        proc { raise StandardError, 'PubNub is away' },
        proc { |_channel, msg, _quiz_id| published << msg }
      )

      worker.send(:handle_mcq_question, mcq, 1, 'quiz-2', 2)

      expect(session).to have_received(:open_question).once
      expect(published.map { |entry| entry[:meta] }).to eq(%w[question answer])
    end

    it 'does not ask a question again when its scoreboard cannot be published' do
      quiz_question = FactoryBot.create(:quiz_question, :mcq, quiz: quiz, question_no: 1)
      allow(session).to receive(:get_scoreboard).and_return([])
      allow(worker).to receive(:publish_with_retry).with(anything, hash_including(meta: 'scoreboard'), anything)
                                                   .and_raise(StandardError, 'PubNub is away')

      expect { worker.send(:run_quiz_questions, quiz, 'quiz-2') }.to raise_error(StandardError, 'PubNub is away')

      expect(session).to have_received(:open_question).once.with(quiz_question.question_no, quiz_question.id, anything)
      expect(published.map { |entry| entry[:meta] }).to eq(%w[question answer])
    end

    it 'keeps the answer out of a multiple choice question until it closes' do
      expect(session).to receive(:open_question).with(1, 5, 30)
      expect(worker).to receive(:sleep).with(30 + window)

      worker.send(:handle_mcq_question, mcq, 1, 'quiz-2', 2)

      expect(message('question')).not_to have_key(:mc_answer)
      expect(message('answer')).to include(q_num: 1, q_type: 'mcq', mc_answer: 'C')
      expect(published.map { |entry| entry[:meta] }).to eq(%w[question answer])
    end

    it 'keeps the reference out of a reference question until it closes' do
      expect(session).to receive(:open_question).with(1, 6, 25)
      expect(worker).to receive(:sleep).with(25 + window)

      worker.send(:handle_reference_question, question, 1, 'John 11:35', passages, 'quiz-2', 2)

      expect(message('question')).not_to have_key(:q_ref)
      expect(message('question')[:q_passages]).to eq(passages)
      expect(message('answer')).to include(q_num: 1, q_type: 'reference', q_ref: 'John 11:35')
    end

    it 'keeps the verse text out of a recitation question until it closes' do
      expect(session).to receive(:open_question).with(1, 6, 20)
      expect(worker).to receive(:sleep).with(20 + window)

      worker.send(:handle_recitation_question, question, 1, 'John 11:35', passages, 'quiz-2', 2)

      expect(message('question')).not_to have_key(:q_passages)
      expect(message('question')[:q_ref]).to eq('John 11:35')
      expect(message('answer')).to include(q_num: 1, q_type: 'recitation', q_passages: passages)
    end
  end

  describe 'announcing the result' do
    def record_with(scoreboard)
      worker.instance_variable_set(:@quiz_session, double('QuizSession', get_scoreboard: scoreboard))
      worker.send(:record_final_scoreboard, quiz, "quiz-#{quiz.id}")
    end

    it 'announces a single winner' do
      expect(Tweet).to receive(:create!).with(news: 'Lisa won Test Quiz', user_id: '10', importance: 2)

      record_with([
        { 'name' => 'Lisa', 'id' => '10', 'score' => '150' },
        { 'name' => 'Phil', 'id' => '20', 'score' => '90' }
      ])
    end

    it 'announces a tie naming every winner' do
      expect(Tweet).to receive(:create!).with(
        news: 'Lisa and Phil tied for first in Test Quiz', user_id: '10', importance: 2
      )

      record_with([
        { 'name' => 'Phil', 'id' => '20', 'score' => '150' },
        { 'name' => 'Lisa', 'id' => '10', 'score' => '150' }
      ])
    end

    it 'posts as many announcements as it takes to name everyone in a long tie' do
      names = Array.new(12) { |i| "#{'x' * 59}#{i.to_s.rjust(2, '0')}" }
      news = []
      allow(Tweet).to receive(:create!) { |args| news << args[:news] }

      record_with(names.each_with_index.map { |name, i| { 'name' => name, 'id' => i.to_s, 'score' => '150' } })

      expect(news.length).to be > 1
      expect(news.map(&:length)).to all(be <= 255)
      expect(names).to all(satisfy { |name| news.join(' ').include?(name) })
    end

    it 'does not post an announcement twice when a later one fails and is retried' do
      names = Array.new(12) { |i| "#{'x' * 59}#{i.to_s.rjust(2, '0')}" }
      news = []
      save_tweet = proc { |args| news << args[:news] }
      allow(Tweet).to receive(:create!).and_invoke(
        save_tweet,
        proc { raise ActiveRecord::StatementInvalid, 'database hiccup' },
        save_tweet
      )

      record_with(names.each_with_index.map { |name, i| { 'name' => name, 'id' => i.to_s, 'score' => '150' } })

      expect(news.length).to be > 1
      expect(news.uniq).to eq(news)
      expect(names).to all(satisfy { |name| news.join(' ').include?(name) })
    end

    it 'reports an announcement that keeps failing and still posts the others' do
      names = Array.new(12) { |i| "#{'x' * 59}#{i.to_s.rjust(2, '0')}" }
      news = []
      always_fail = proc { raise ActiveRecord::StatementInvalid, 'database hiccup' }
      allow(Tweet).to receive(:create!).and_invoke(always_fail, always_fail, always_fail, always_fail, proc { |args| news << args[:news] })
      allow(Sentry).to receive(:capture_exception)

      record_with(names.each_with_index.map { |name, i| { 'name' => name, 'id' => i.to_s, 'score' => '150' } })

      expect(Sentry).to have_received(:capture_exception).once
      expect(news).not_to be_empty
      expect(news.join(' ')).to include(names.last)
    end

    it 'retries the final scoreboard rather than announcing no winner when Redis fails' do
      session = instance_double(QuizSession)
      allow(session).to receive(:get_scoreboard).with(raise_errors: true).and_invoke(
        proc { raise Redis::CannotConnectError },
        proc { [{ 'name' => 'Lisa', 'id' => '10', 'score' => '150' }] }
      )
      worker.instance_variable_set(:@quiz_session, session)

      expect(Tweet).to receive(:create!).with(news: 'Lisa won Test Quiz', user_id: '10', importance: 2)

      worker.send(:record_final_scoreboard, quiz, "quiz-#{quiz.id}")
    end

    it 'announces nothing when nobody scored any points' do
      expect(Tweet).not_to receive(:create!)

      record_with([{ 'name' => 'Lisa', 'id' => '10', 'score' => '0' }])
    end
  end
end