require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe KnowledgeQuiz, type: :worker do
  let(:worker) { described_class.new }
  let(:quiz) { FactoryBot.create(:quiz, id: 1, start_time: 1.hour.from_now) }
  let(:quiz_session) { instance_double(QuizSession) }
  
  before do
    Sidekiq::Testing.inline!
    allow(QuizSession).to receive(:new).with(1).and_return(quiz_session)
    allow(quiz_session).to receive(:set_quiz_status)
    allow(quiz_session).to receive(:cleanup_quiz_data)
    allow(quiz_session).to receive(:cleanup_legacy_data)
    allow(quiz_session).to receive(:get_scoreboard).and_return([])
    allow(quiz_session).to receive(:get_question_stats).and_return([])
    allow(quiz_session).to receive(:get_quiz_metadata).and_return({})
    allow(quiz_session).to receive(:unlock_quiz)
    allow(quiz_session).to receive(:update_question_stats)
    
    # Mock PubNub
    allow(PN).to receive(:publish)
    
    # Create quiz
    quiz
  end
  
  after do
    Sidekiq::Testing.disable!
    $redis.flushdb
  end
  
  describe '#perform' do
    context 'when multiple processes try to run the quiz simultaneously' do
      it 'only allows one process to execute the quiz' do
        # First process acquires the lock
        allow(worker).to receive(:quiz_recently_executed?).and_return(false)
        allow(worker).to receive(:acquire_execution_window_lock).and_return(true)
        allow(quiz_session).to receive(:lock_quiz).and_return(true)
        allow(quiz_session).to receive(:quiz_in_progress?).and_return(false)
        
        # Create approved quiz questions
        FactoryBot.create_list(:quiz_question, 3, :mcq, approval_status: 'Approved', last_asked: 1.month.ago)
        
        # Mock sleep to speed up tests
        allow(worker).to receive(:sleep)
        
        # Start first worker (should succeed)
        expect(Tweet).to receive(:create!).with(
          news: "The Bible knowledge quiz is starting. <a href=\"live_quiz\">Join now!</a>",
          user_id: 1,
          importance: 2
        ).at_least(:once)
        
        # Start the worker in a thread to simulate concurrent execution
        thread1 = Thread.new { worker.perform }
        
        # Try to start second worker (should be blocked)
        worker2 = described_class.new
        allow(worker2).to receive(:quiz_recently_executed?).and_return(false)
        allow(worker2).to receive(:acquire_execution_window_lock).and_return(false)
        
        expect(worker2).not_to receive(:announce_quiz_start)
        worker2.perform
        
        thread1.join
      end
    end
    
    context 'when quiz was recently executed' do
      it 'prevents re-execution within the execution window' do
        # Set that quiz was recently executed
        $redis.set(KnowledgeQuiz::EXECUTION_WINDOW_KEY, Time.current.utc.iso8601, ex: 300)
        
        # Should not create any tweets
        expect(Tweet).not_to receive(:create!)
        
        worker.perform
      end
    end
    
    context 'when execution window has passed' do
      it 'allows quiz to run again' do
        # Set that quiz was executed 6 minutes ago (outside the 5-minute window)
        $redis.set(KnowledgeQuiz::EXECUTION_WINDOW_KEY, 6.minutes.ago.iso8601, ex: 1)
        
        allow(worker).to receive(:acquire_execution_window_lock).and_return(true)
        allow(quiz_session).to receive(:lock_quiz).and_return(true)
        allow(quiz_session).to receive(:quiz_in_progress?).and_return(false)
        
        # Create approved quiz questions
        FactoryBot.create_list(:quiz_question, 3, :mcq, approval_status: 'Approved', last_asked: 1.month.ago)
        
        # Mock sleep to speed up tests
        allow(worker).to receive(:sleep)
        
        # Should create announcement tweet
        expect(Tweet).to receive(:create!).with(
          hash_including(news: /Bible knowledge quiz is starting/)
        ).at_least(:once)
        
        worker.perform
      end
    end
    
    context 'cleanup after quiz completion' do
      it 'cleans up all locks including execution window lock' do
        allow(worker).to receive(:quiz_recently_executed?).and_return(false)
        allow(worker).to receive(:acquire_execution_window_lock).and_return(true)
        allow(quiz_session).to receive(:lock_quiz).and_return(true)
        allow(quiz_session).to receive(:quiz_in_progress?).and_return(false)
        
        # Create approved quiz questions
        FactoryBot.create_list(:quiz_question, 3, :mcq, approval_status: 'Approved', last_asked: 1.month.ago)
        
        # Mock sleep to speed up tests
        allow(worker).to receive(:sleep)
        
        # Allow tweets to be created
        allow(Tweet).to receive(:create!)
        
        worker.perform
        
        # Check that execution lock was cleaned up
        expect($redis.exists("#{KnowledgeQuiz::QUIZ_LOCK_KEY}_execution")).to eq(0)
      end
    end
  end
  
  describe 'lock management methods' do
    describe '#quiz_recently_executed?' do
      it 'returns true when quiz was executed within window' do
        $redis.set(KnowledgeQuiz::EXECUTION_WINDOW_KEY, 2.minutes.ago.iso8601)
        expect(worker.send(:quiz_recently_executed?)).to be true
      end
      
      it 'returns false when quiz was executed outside window' do
        $redis.set(KnowledgeQuiz::EXECUTION_WINDOW_KEY, 6.minutes.ago.iso8601)
        expect(worker.send(:quiz_recently_executed?)).to be false
      end
      
      it 'returns false when no previous execution' do
        expect(worker.send(:quiz_recently_executed?)).to be false
      end
    end
    
    describe '#acquire_execution_window_lock' do
      it 'acquires lock when available' do
        result = worker.send(:acquire_execution_window_lock)
        expect(result).to be true
        expect($redis.exists("#{KnowledgeQuiz::QUIZ_LOCK_KEY}_execution")).to eq(1)
      end
      
      it 'fails to acquire lock when already taken' do
        # First acquisition
        worker.send(:acquire_execution_window_lock)
        
        # Second attempt should fail
        worker2 = described_class.new
        result = worker2.send(:acquire_execution_window_lock)
        expect(result).to be false
      end
      
      it 'sets execution window timestamp when acquiring lock' do
        worker.send(:acquire_execution_window_lock)
        timestamp = $redis.get(KnowledgeQuiz::EXECUTION_WINDOW_KEY)
        expect(timestamp).not_to be_nil
        expect(Time.parse(timestamp)).to be_within(1.second).of(Time.current.utc)
      end
    end
  end
  
  describe 'tweet creation' do
    context 'during successful quiz execution' do
      before do
        allow(worker).to receive(:quiz_recently_executed?).and_return(false)
        allow(worker).to receive(:acquire_execution_window_lock).and_return(true)
        allow(quiz_session).to receive(:lock_quiz).and_return(true)
        allow(quiz_session).to receive(:quiz_in_progress?).and_return(false)
        
        # Create approved quiz questions
        FactoryBot.create_list(:quiz_question, 3, :mcq, approval_status: 'Approved', last_asked: 1.month.ago)
        
        # Mock sleep to speed up tests
        allow(worker).to receive(:sleep)
        
        # Mock iOS notifications
        allow(worker).to receive(:ios_quiz_alert)
      end
      
      it 'creates exactly 2 tweets (start and winner) when there are participants' do
        # Mock a winner
        allow(quiz_session).to receive(:get_scoreboard).and_return([
          { 'name' => 'John Doe', 'id' => 123, 'score' => 100 }
        ])
        
        tweet_count = 0
        allow(Tweet).to receive(:create!) do |args|
          tweet_count += 1
          instance_double(Tweet, id: tweet_count, created_at: Time.current)
        end
        
        worker.perform
        
        expect(tweet_count).to eq(2)
      end
      
      it 'creates only 1 tweet (start) when there are no participants' do
        # No participants in scoreboard
        allow(quiz_session).to receive(:get_scoreboard).and_return([])
        
        tweet_count = 0
        allow(Tweet).to receive(:create!) do |args|
          tweet_count += 1
          instance_double(Tweet, id: tweet_count, created_at: Time.current)
        end
        
        worker.perform
        
        expect(tweet_count).to eq(1)
      end
      
      it 'logs tweet creation with process ID' do
        allow(Tweet).to receive(:create!).and_return(
          instance_double(Tweet, id: 1, created_at: Time.current)
        )
        
        expect(Sidekiq.logger).to receive(:info).with(/Creating quiz start announcement tweet \(Process: \d+\)/).at_least(:once)
        expect(Sidekiq.logger).to receive(:info).with(/Created tweet ID: 1/).at_least(:once)
        allow(Sidekiq.logger).to receive(:info)
        
        worker.perform
      end
    end
  end

  describe 'badge awarding' do
    let(:quiz_champion_badge) { FactoryBot.create(:badge, name: 'Quiz Champion', color: 'solo', description: 'Won a weekly Bible knowledge quiz') }
    let(:winner_user) { FactoryBot.create(:user) }

    before do
      allow(worker).to receive(:quiz_recently_executed?).and_return(false)
      allow(worker).to receive(:acquire_execution_window_lock).and_return(true)
      allow(quiz_session).to receive(:lock_quiz).and_return(true)
      allow(quiz_session).to receive(:quiz_in_progress?).and_return(false)

      # Create approved quiz questions
      FactoryBot.create_list(:quiz_question, 3, :mcq, approval_status: 'Approved', last_asked: 1.month.ago)

      # Mock sleep to speed up tests
      allow(worker).to receive(:sleep)

      # Mock iOS notifications
      allow(worker).to receive(:ios_quiz_alert)

      # Create the badge
      quiz_champion_badge
    end

    context 'when there is a quiz winner' do
      before do
        # Mock a winner
        allow(quiz_session).to receive(:get_scoreboard).and_return([
          { 'name' => winner_user.name, 'id' => winner_user.id, 'score' => 100 },
          { 'name' => 'Jane Smith', 'id' => 456, 'score' => 80 }
        ])

        allow(Tweet).to receive(:create!).and_return(
          instance_double(Tweet, id: 1, created_at: Time.current)
        )
      end

      it 'awards the Quiz Champion badge to the winner' do
        expect_any_instance_of(Badge).to receive(:award_badge).with(winner_user)

        worker.perform
      end

      it 'logs badge awarding success' do
        allow_any_instance_of(Badge).to receive(:award_badge)

        expect(Sidekiq.logger).to receive(:info).with(/Awarded Quiz Champion badge to #{winner_user.name}/)
        allow(Sidekiq.logger).to receive(:info)

        worker.perform
      end

      it 'does not award badge if user already has it' do
        # User already has the badge
        winner_user.badges << quiz_champion_badge

        expect_any_instance_of(Badge).to receive(:award_badge).with(winner_user).and_call_original

        worker.perform

        # Should still have only one badge
        expect(winner_user.badges.count).to eq(1)
      end
    end

    context 'when Quiz Champion badge does not exist' do
      before do
        # Delete the badge
        quiz_champion_badge.destroy

        # Create admin user for tweet creation
        FactoryBot.create(:user, id: 1, admin: true)

        # Mock a winner
        allow(quiz_session).to receive(:get_scoreboard).and_return([
          { 'name' => winner_user.name, 'id' => winner_user.id, 'score' => 100 }
        ])

        allow(Tweet).to receive(:create!).and_return(
          instance_double(Tweet, id: 1, created_at: Time.current)
        )
      end

      it 'logs an error and continues quiz execution' do
        expect(Sidekiq.logger).to receive(:error).with(/Quiz Champion badge not found/)
        allow(Sidekiq.logger).to receive(:info)
        allow(Sidekiq.logger).to receive(:error)

        # Should not raise an error
        expect { worker.perform }.not_to raise_error
      end
    end

    context 'when badge awarding fails' do
      before do
        # Create admin user for tweet creation
        FactoryBot.create(:user, id: 1, admin: true)

        # Mock a winner
        allow(quiz_session).to receive(:get_scoreboard).and_return([
          { 'name' => 'Invalid User', 'id' => 999999, 'score' => 100 }
        ])

        allow(Tweet).to receive(:create!).and_return(
          instance_double(Tweet, id: 1, created_at: Time.current)
        )
      end

      it 'logs the error and continues quiz execution' do
        expect(Sidekiq.logger).to receive(:error).with(/Failed to award Quiz Champion badge/)
        allow(Sidekiq.logger).to receive(:info)
        allow(Sidekiq.logger).to receive(:error)

        # Should not raise an error
        expect { worker.perform }.not_to raise_error
      end
    end
  end
end