require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe KnowledgeQuiz, type: :worker do # skipcq: RB-R1001 (one example group covers the whole quiz run)
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
    allow(quiz_session).to receive(:open_question)
    allow(quiz_session).to receive(:restart_answer_window)

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
  
  describe 'publishing questions' do
    let!(:question) { FactoryBot.create(:quiz_question, :mcq, approval_status: 'Approved', last_asked: 1.month.ago) }
    let(:published) { [] }

    before do
      allow(worker).to receive(:quiz_recently_executed?).and_return(false)
      allow(worker).to receive(:acquire_execution_window_lock).and_return(true)
      allow(quiz_session).to receive(:lock_quiz).and_return(true)
      allow(quiz_session).to receive(:quiz_in_progress?).and_return(false)
      allow(worker).to receive(:sleep)
      allow(worker).to receive(:ios_quiz_alert)
      allow(Tweet).to receive(:create!).and_return(instance_double(Tweet, id: 1, created_at: Time.current))
      allow(PN).to receive(:publish) { |args| published << args[:message] }
    end

    it 'leaves the correct answer out of the question message, sending the placeholder the iOS app needs' do
      worker.perform

      question_messages = published.select { |message| message[:meta] == 'question' }
      expect(question_messages).not_to be_empty
      expect(question_messages.map { |message| message[:mc_answer] }).to all(eq(QuizSession::IOS_ANSWER_PLACEHOLDER))
    end

    it 'opens each question for its time allocation before publishing it' do
      expect(quiz_session).to receive(:open_question)
        .with(1, question.id, question.time_allocation).ordered
      expect(PN).to receive(:publish).with(hash_including(message: hash_including(meta: 'question', q_num: 1))).ordered
      allow(quiz_session).to receive(:open_question)
      allow(PN).to receive(:publish)

      worker.perform
    end

    it 'restarts the answer window after publishing, so that publishing takes no time from players' do
      expect(PN).to receive(:publish).with(hash_including(message: hash_including(meta: 'question', q_num: 1))).ordered
      expect(quiz_session).to receive(:restart_answer_window).with(1, question.time_allocation).ordered
      allow(PN).to receive(:publish)
      allow(quiz_session).to receive(:restart_answer_window)

      worker.perform
    end

    it 'retries a failed restart of the answer window without publishing the question again' do
      allow(quiz_session).to receive(:restart_answer_window).and_invoke(proc { raise Redis::CannotConnectError }, proc { true })

      worker.perform

      expect(quiz_session).to have_received(:open_question).exactly(5).times
      expect(published.select { |message| message[:meta] == 'question' }.map { |message| message[:q_num] }).to eq([1, 2, 3, 4, 5])
    end

    it 'reports a restart of the answer window that keeps failing and carries on' do
      allow(quiz_session).to receive(:restart_answer_window).and_raise(Redis::CannotConnectError)
      allow(Sentry).to receive(:capture_exception)

      worker.perform

      expect(Sentry).to have_received(:capture_exception).exactly(5).times
      expect(published.select { |message| message[:meta] == 'question' }.map { |message| message[:q_num] }).to eq([1, 2, 3, 4, 5])
    end

    it 'does not publish a question that could not be opened' do
      allow(quiz_session).to receive(:open_question).and_raise(Redis::CannotConnectError)

      worker.perform

      expect(published.map { |message| message[:meta] }).not_to include('question')
    end

    it 'never reopens a question after publishing its answer fails' do
      allow(PN).to receive(:publish).with(hash_including(message: hash_including(meta: 'answer', q_num: 1))).and_invoke(
        proc { raise StandardError, 'PubNub is away' },
        proc { |args| published << args[:message] }
      )

      worker.perform

      expect(PN).to have_received(:publish).with(hash_including(message: hash_including(meta: 'answer', q_num: 1))).twice
      expect(quiz_session).to have_received(:open_question).exactly(5).times
      expect(published.select { |message| message[:meta] == 'question' }.map { |message| message[:q_num] }).to eq([1, 2, 3, 4, 5])
    end

    it 'does not ask a question again when its scoreboard cannot be published' do
      allow(PN).to receive(:publish).with(hash_including(message: hash_including(meta: 'scoreboard')))
                                    .and_raise(StandardError, 'PubNub is away')

      worker.perform

      expect(published.count { |message| message[:meta] == 'question' }).to eq(1)
      expect(quiz_session).to have_received(:open_question).once
    end

    it 'reveals the answer only after the answer window has closed' do
      events = []
      allow(worker).to receive(:sleep) { |seconds| events << [:sleep, seconds] }
      allow(PN).to receive(:publish) { |args| events << [args[:message][:meta], args[:message]] }

      worker.perform

      question_at = events.index { |event| event.first == 'question' }
      answer_at   = events.index { |event| event.first == 'answer' }
      window      = question.time_allocation + QuizSession::ANSWER_GRACE_SECONDS

      expect(events[question_at + 1]).to eq([:sleep, window])
      expect(answer_at).to eq(question_at + 2)
      expect(events[answer_at].last).to include(q_num: 1, q_type: 'mcq', mc_answer: 'B')
    end

    it 'reveals the answer before publishing the scoreboard for that question' do
      worker.perform

      metas = published.map { |message| message[:meta] }
      expect(metas.index('answer')).to be < metas.index('scoreboard')
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

      context 'with a tie for first place' do
        let(:created_tweets) { [] }

        before do
          allow(quiz_session).to receive(:get_scoreboard).and_return([
            { 'name' => 'Phil', 'id' => '20', 'score' => '150' },
            { 'name' => 'Lisa', 'id' => '10', 'score' => '150' },
            { 'name' => 'Sam', 'id' => '30', 'score' => '90' }
          ])

          allow(Tweet).to receive(:create!) do |args|
            created_tweets << args
            instance_double(Tweet, id: created_tweets.length, created_at: Time.current)
          end
        end

        it 'announces one tie naming every winner and nobody else' do
          worker.perform

          expect(created_tweets.length).to eq(2)
          expect(created_tweets.last[:news]).to eq('Lisa and Phil tied for first in the Bible knowledge quiz')
          expect(created_tweets.last[:user_id]).to eq('10')
        end

        it 'reports an announcement that keeps failing and still posts the others and awards the badges' do
          names = Array.new(12) { |i| "#{'x' * 59}#{i.to_s.rjust(2, '0')}" }
          allow(quiz_session).to receive(:get_scoreboard).and_return(
            names.each_with_index.map { |name, i| { 'name' => name, 'id' => i.to_s, 'score' => '150' } }
          )
          always_fail = proc { raise ActiveRecord::StatementInvalid, 'database hiccup' }
          save_tweet = proc do |args|
            created_tweets << args
            instance_double(Tweet, id: created_tweets.length, created_at: Time.current)
          end
          allow(Tweet).to receive(:create!).with(hash_including(news: a_string_matching(/tied for first/)))
                                           .and_invoke(always_fail, always_fail, always_fail, always_fail, save_tweet)
          allow(Sentry).to receive(:capture_exception)
          allow(worker).to receive(:award_quiz_champion_badges)

          worker.perform

          expect(Sentry).to have_received(:capture_exception).once
          expect(created_tweets.map { |tweet| tweet[:news] }.join(' ')).to include(names.last)
          expect(worker).to have_received(:award_quiz_champion_badges)
        end

        it 'does not post an announcement twice when a later one fails and is retried' do
          names = Array.new(12) { |i| "#{'x' * 59}#{i.to_s.rjust(2, '0')}" }
          allow(quiz_session).to receive(:get_scoreboard).and_return(
            names.each_with_index.map { |name, i| { 'name' => name, 'id' => i.to_s, 'score' => '150' } }
          )
          save_tweet = proc do |args|
            created_tweets << args
            instance_double(Tweet, id: created_tweets.length, created_at: Time.current)
          end
          allow(Tweet).to receive(:create!).with(hash_including(news: a_string_matching(/tied for first/))).and_invoke(
            save_tweet,
            proc { raise ActiveRecord::StatementInvalid, 'database hiccup' },
            save_tweet
          )

          worker.perform

          winner_news = created_tweets.map { |tweet| tweet[:news] }.grep(/tied for first/)
          expect(winner_news.length).to be > 1
          expect(winner_news.uniq).to eq(winner_news)
          expect(names).to all(satisfy { |name| winner_news.join(' ').include?(name) })
        end

        it 'posts as many announcements as it takes to name everyone in a long tie' do
          names = Array.new(12) { |i| "#{'x' * 59}#{i.to_s.rjust(2, '0')}" }
          allow(quiz_session).to receive(:get_scoreboard).and_return(
            names.each_with_index.map { |name, i| { 'name' => name, 'id' => i.to_s, 'score' => '150' } }
          )

          worker.perform

          winner_news = created_tweets.map { |tweet| tweet[:news] }.grep(/tied for first/)
          expect(winner_news.length).to be > 1
          expect(winner_news.map(&:length)).to all(be <= 255)
          expect(names).to all(satisfy { |name| winner_news.join(' ').include?(name) })
        end
      end

      it 'keeps the existing wording for a single winner' do
        allow(quiz_session).to receive(:get_scoreboard).and_return([
          { 'name' => 'Phil', 'id' => '20', 'score' => '150' },
          { 'name' => 'Lisa', 'id' => '10', 'score' => '140' }
        ])
        created_tweets = []
        allow(Tweet).to receive(:create!) do |args|
          created_tweets << args
          instance_double(Tweet, id: created_tweets.length, created_at: Time.current)
        end

        worker.perform

        expect(created_tweets.last[:news]).to eq('Phil won the Bible knowledge quiz')
      end

      it 'announces no winner when nobody scored any points' do
        allow(quiz_session).to receive(:get_scoreboard).and_return([
          { 'name' => 'Phil', 'id' => '20', 'score' => '0' },
          { 'name' => 'Lisa', 'id' => '10', 'score' => '0' }
        ])
        created_tweets = []
        allow(Tweet).to receive(:create!) do |args|
          created_tweets << args
          instance_double(Tweet, id: created_tweets.length, created_at: Time.current)
        end

        worker.perform

        expect(created_tweets.length).to eq(1)
        expect(created_tweets.first[:news]).to include('is starting')
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

  describe 'question statistics at the end of a quiz' do
    let(:winner_user) { FactoryBot.create(:user, name: 'Lisa') }
    let!(:answered_question) { FactoryBot.create(:quiz_question, :mcq, times_answered: 10, perc_correct: 50) }
    let!(:new_question) { FactoryBot.create(:quiz_question, :mcq, times_answered: 0, perc_correct: 50) }

    before do
      allow(worker).to receive(:quiz_recently_executed?).and_return(false)
      allow(worker).to receive(:acquire_execution_window_lock).and_return(true)
      allow(quiz_session).to receive(:lock_quiz).and_return(true)
      allow(quiz_session).to receive(:quiz_in_progress?).and_return(false)
      allow(worker).to receive(:sleep)
      allow(worker).to receive(:ios_quiz_alert)

      FactoryBot.create_list(:quiz_question, 3, :mcq, approval_status: 'Approved', last_asked: 1.month.ago)

      allow(quiz_session).to receive(:get_scoreboard).and_return([
        { 'name' => winner_user.name, 'id' => winner_user.id, 'score' => 100 }
      ])
      allow(quiz_session).to receive(:get_question_stats).and_return([
        { 'qq_id' => answered_question.id.to_s, 'answered' => '10', 'total_score' => '100' },
        { 'qq_id' => new_question.id.to_s }
      ])
      allow(Tweet).to receive(:create!).and_call_original
      allow(worker).to receive(:mark_quiz_failed)
    end

    def expect_winner_announced_and_quiz_completed
      expect(Tweet).to have_received(:create!).with(hash_including(news: /Lisa won the Bible knowledge quiz/))
      expect(worker).not_to have_received(:mark_quiz_failed)
    end

    it 'announces the winner when a question has never been answered correctly' do
      worker.perform

      expect_winner_announced_and_quiz_completed
      expect(new_question.reload.times_answered).to eq(0)
      expect(new_question.perc_correct).to eq(50)
    end

    it 'counts each question once and still announces the winner when one question cannot be saved' do
      allow(QuizQuestion).to receive(:find).and_call_original
      allow(QuizQuestion).to receive(:find).with(new_question.id).and_raise(ActiveRecord::StatementInvalid, 'database hiccup')
      allow(Sidekiq.logger).to receive(:error)
      allow(Sentry).to receive(:capture_exception)

      worker.perform

      expect_winner_announced_and_quiz_completed
      expect(answered_question.reload.times_answered).to eq(20)
      expect(Sidekiq.logger).to have_received(:error).with(/Could not update difficulty of question #{new_question.id}: .*database hiccup/)
      expect(Sentry).to have_received(:capture_exception).with(an_instance_of(ActiveRecord::StatementInvalid))
    end

  end

  describe 'badge awarding' do
    let(:quiz_champion_badge) { FactoryBot.create(:badge, name: 'Quiz Champion', color: 'solo', description: 'Won a weekly Bible knowledge quiz', auto_award: false) }
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

    context 'when there is a tie for first place' do
      let(:other_winner) { FactoryBot.create(:user) }
      let(:runner_up) { FactoryBot.create(:user) }

      before do
        allow(quiz_session).to receive(:get_scoreboard).and_return([
          { 'name' => winner_user.name, 'id' => winner_user.id.to_s, 'score' => '150' },
          { 'name' => other_winner.name, 'id' => other_winner.id.to_s, 'score' => '150' },
          { 'name' => runner_up.name, 'id' => runner_up.id.to_s, 'score' => '90' }
        ])

        allow(Tweet).to receive(:create!).and_return(
          instance_double(Tweet, id: 1, created_at: Time.current)
        )
      end

      it 'awards the badge to every tied winner but not the runner-up' do
        worker.perform

        expect(winner_user.badges).to include(quiz_champion_badge)
        expect(other_winner.badges).to include(quiz_champion_badge)
        expect(runner_up.badges).not_to include(quiz_champion_badge)
      end

      it 'still awards the other winner when one award fails' do
        allow(quiz_session).to receive(:get_scoreboard).and_return([
          { 'name' => 'Aaa Missing', 'id' => '999999', 'score' => '150' },
          { 'name' => 'Zzz Present', 'id' => other_winner.id.to_s, 'score' => '150' }
        ])

        expect(Sidekiq.logger).to receive(:error).with(/Failed to award Quiz Champion badge/)
        allow(Sidekiq.logger).to receive(:info)
        allow(Sidekiq.logger).to receive(:error)

        worker.perform

        expect(other_winner.badges).to include(quiz_champion_badge)
      end
    end

    context 'when nobody scored any points' do
      before do
        allow(quiz_session).to receive(:get_scoreboard).and_return([
          { 'name' => winner_user.name, 'id' => winner_user.id.to_s, 'score' => '0' }
        ])

        allow(Tweet).to receive(:create!).and_return(
          instance_double(Tweet, id: 1, created_at: Time.current)
        )
      end

      it 'does not award the badge' do
        worker.perform

        expect(winner_user.badges).not_to include(quiz_champion_badge)
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