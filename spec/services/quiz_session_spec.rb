require 'spec_helper'

RSpec.describe QuizSession, type: :service do
  let(:quiz_id) { 42 }
  let(:quiz_session) { QuizSession.new(quiz_id) }
  let(:user_id) { 123 }
  let(:user_name) { "Test User" }
  let(:user_login) { "test@example.com" }
  let(:question_num) { 1 }
  let(:question_id) { 456 }
  let(:score) { 8 }
  
  before do
    # Clean up any existing test data
    quiz_session.cleanup_quiz_data
  end
  
  after do
    # Clean up after each test
    quiz_session.cleanup_quiz_data
  end

  describe '#initialize' do
    it 'sets the quiz_id correctly' do
      expect(quiz_session.quiz_id).to eq(quiz_id)
    end
    
    it 'converts string quiz_id to integer' do
      session = QuizSession.new("42")
      expect(session.quiz_id).to eq(42)
    end
  end

  describe 'participant management' do
    describe '#add_participant' do
      it 'adds a participant successfully' do
        result = quiz_session.add_participant(user_id, user_name, user_login)
        expect(result).to be true
      end
      
      it 'stores participant data in Redis' do
        quiz_session.add_participant(user_id, user_name, user_login)
        participants = quiz_session.get_participants
        
        expect(participants.length).to eq(1)
        participant = participants.first
        expect(participant['id']).to eq(user_id.to_s)
        expect(participant['name']).to eq(user_name)
        expect(participant['login']).to eq(user_login)
        expect(participant['score']).to eq('0')
      end

      it 'restores scoreboard membership when an earlier attempt stopped after creating the hash' do
        quiz_session.add_participant(user_id, user_name, user_login)
        $redis.srem(quiz_session.send(:participant_set_key), user_id.to_s)
        expect(quiz_session.get_scoreboard).to eq([])

        quiz_session.add_participant(user_id, user_name, user_login)

        expect(quiz_session.get_scoreboard.map { |entry| entry['id'] }).to eq([user_id.to_s])
      end

      it 'does not overwrite a score when the same player is added at the same moment' do
        quiz_session.add_participant(user_id, user_name, user_login)
        $redis.hincrby(quiz_session.send(:participant_key, user_id), 'score', 10)
        allow($redis).to receive(:exists).and_return(0)

        quiz_session.add_participant(user_id, 'Other Name', user_login)

        participant = quiz_session.get_scoreboard.first
        expect(participant).to include('score' => '10', 'name' => user_name)
      end

      it 'keeps the score of a participant who is added again' do
        quiz_session.add_participant(user_id, user_name, user_login)
        $redis.hincrby(quiz_session.send(:participant_key, user_id), 'score', 10)

        quiz_session.add_participant(user_id, user_name, user_login)

        expect(quiz_session.get_scoreboard.first['score']).to eq('10')
      end
    end

    describe '#get_participants' do
      it 'returns empty array when no participants' do
        expect(quiz_session.get_participants).to eq([])
      end
      
      it 'returns all participants' do
        quiz_session.add_participant(user_id, user_name, user_login)
        quiz_session.add_participant(456, "Another User", "another@example.com")
        
        participants = quiz_session.get_participants
        expect(participants.length).to eq(2)
      end
    end
    
    describe '#get_scoreboard' do
      context 'when Redis fails' do
        before do
          allow(quiz_session.instance_variable_get(:@redis)).to receive(:smembers).and_raise(Redis::CannotConnectError)
        end

        it 'returns an empty scoreboard by default' do
          expect(quiz_session.get_scoreboard).to eq([])
        end

        it 'raises when asked to, so that a failed read is not taken to mean nobody played' do
          expect { quiz_session.get_scoreboard(raise_errors: true) }.to raise_error(Redis::CannotConnectError)
        end
      end

      it 'returns participants sorted by score descending' do
        # Add participants with different scores
        quiz_session.add_participant(1, "User 1", "user1@example.com")
        quiz_session.add_participant(2, "User 2", "user2@example.com")
        quiz_session.add_participant(3, "User 3", "user3@example.com")
        
        # Update scores
        quiz_session.open_question(1, question_id, 30)
        quiz_session.record_answer(1, 1, 5)
        quiz_session.record_answer(1, 2, 10)
        quiz_session.record_answer(1, 3, 7)

        scoreboard = quiz_session.get_scoreboard
        expect(scoreboard.length).to eq(3)
        expect(scoreboard[0]['name']).to eq("User 2")  # Highest score
        expect(scoreboard[0]['score']).to eq('10')
        expect(scoreboard[1]['name']).to eq("User 3")  # Second highest
        expect(scoreboard[1]['score']).to eq('7')
        expect(scoreboard[2]['name']).to eq("User 1")  # Lowest score
        expect(scoreboard[2]['score']).to eq('5')
      end

      it 'orders tied participants by name so the order is stable' do
        quiz_session.add_participant(1, "Zoe", "zoe@example.com")
        quiz_session.add_participant(2, "adam", "adam@example.com")
        quiz_session.add_participant(3, "Mia", "mia@example.com")

        quiz_session.open_question(1, question_id, 30)
        [1, 2].each { |id| quiz_session.record_answer(1, id, 10) }
        quiz_session.record_answer(1, 3, 20)

        expect(quiz_session.get_scoreboard.map { |p| p['name'] }).to eq(%w[Mia adam Zoe])
      end
    end
  end

  describe '.winners' do
    it 'returns the single top scorer' do
      scoreboard = [
        { 'name' => 'Ann', 'id' => '1', 'score' => '30' },
        { 'name' => 'Bob', 'id' => '2', 'score' => '20' }
      ]

      expect(described_class.winners(scoreboard).map { |w| w['name'] }).to eq(['Ann'])
    end

    it 'returns everyone tied on the top score, ordered by name' do
      scoreboard = [
        { 'name' => 'Cal', 'id' => '3', 'score' => '150' },
        { 'name' => 'ann', 'id' => '1', 'score' => '150' },
        { 'name' => 'Bob', 'id' => '2', 'score' => '90' }
      ]

      expect(described_class.winners(scoreboard).map { |w| w['name'] }).to eq(%w[ann Cal])
    end

    it 'compares scores numerically because Redis returns strings' do
      scoreboard = [
        { 'name' => 'Ann', 'id' => '1', 'score' => '90' },
        { 'name' => 'Bob', 'id' => '2', 'score' => '100' }
      ]

      expect(described_class.winners(scoreboard).map { |w| w['name'] }).to eq(['Bob'])
    end

    it 'returns nobody when no one scored any points' do
      scoreboard = [
        { 'name' => 'Ann', 'id' => '1', 'score' => '0' },
        { 'name' => 'Bob', 'id' => '2', 'score' => '0' }
      ]

      expect(described_class.winners(scoreboard)).to eq([])
    end

    it 'returns nobody for an empty scoreboard' do
      expect(described_class.winners([])).to eq([])
    end
  end

  describe '.winner_announcements' do
    it 'names a single winner' do
      winners = [{ 'name' => 'Ann' }]

      expect(described_class.winner_announcements(winners, 'the Bible knowledge quiz'))
        .to eq(['Ann won the Bible knowledge quiz'])
    end

    it 'names both people in a two-way tie' do
      winners = [{ 'name' => 'Ann' }, { 'name' => 'Bob' }]

      expect(described_class.winner_announcements(winners, 'the Bible knowledge quiz'))
        .to eq(['Ann and Bob tied for first in the Bible knowledge quiz'])
    end

    it 'names everyone in a larger tie' do
      winners = [{ 'name' => 'Ann' }, { 'name' => 'Bob' }, { 'name' => 'Cal' }]

      expect(described_class.winner_announcements(winners, 'the Bible knowledge quiz'))
        .to eq(['Ann, Bob, and Cal tied for first in the Bible knowledge quiz'])
    end

    it 'keeps the winner message when escaping makes a valid name too long' do
      announcement = described_class.winner_announcements([{ 'name' => '"' * 43 }], 'the quiz').first

      expect(announcement).to end_with('... won the quiz')
      expect(announcement.length).to be <= 255
      expect(announcement.delete_suffix('... won the quiz').scan('&quot;').join).to eq(announcement.delete_suffix('... won the quiz'))
    end

    it 'does not shorten a name that exactly fits once escaped' do
      ending = ' won Quiz'
      name = '"' * ((255 - ending.length) / '&quot;'.length)

      expect(described_class.winner_announcements([{ 'name' => name }], 'Quiz'))
        .to eq(["#{'&quot;' * name.length}#{ending}"])
    end

    it 'keeps the tie message when escaping makes a name too long' do
      announcements = described_class.winner_announcements([{ 'name' => '"' * 60 }, { 'name' => 'Bob' }], 'the quiz')

      expect(announcements).to all(end_with('tied for first in the quiz'))
      expect(announcements.map(&:length)).to all(be <= 255)
      expect(announcements.join(' ')).to include('Bob')
    end

    it 'escapes HTML in the name of a single winner' do
      winners = [{ 'name' => '<a href="https://example.com">Ann</a>' }]

      expect(described_class.winner_announcements(winners, 'the quiz'))
        .to eq(['&lt;a href=&quot;https://example.com&quot;&gt;Ann&lt;/a&gt; won the quiz'])
    end

    it 'escapes HTML in the names of a tie, counting the escaped text towards the length' do
      name = '<' * 40
      winners = Array.new(3) { { 'name' => name } }

      announcements = described_class.winner_announcements(winners, 'the quiz')

      expect(announcements.join).not_to include('<')
      expect(announcements.map(&:length)).to all(be <= 255)
      expect(announcements.join.scan('&lt;' * 40).length).to eq(3)
    end

    it 'shows an escaped name as plain text once the news item is sanitized' do
      winners = [{ 'name' => '<img src="https://example.com/x.png">' }]

      announcement = described_class.winner_announcements(winners, 'the quiz').first

      expect(ActionController::Base.helpers.sanitize(announcement)).not_to include('<img')
    end

    it 'splits a tie too long for the 255 character news column and names every winner' do
      names = Array.new(12) { |i| "#{'x' * 59}#{i.to_s.rjust(2, '0')}" }

      announcements = described_class.winner_announcements(names.map { |name| { 'name' => name } }, 'the Bible knowledge quiz')

      expect(announcements.length).to be > 1
      expect(announcements).to all(end_with('tied for first in the Bible knowledge quiz'))
      expect(announcements.map(&:length)).to all(be <= 255)
      expect(names).to all(satisfy { |name| announcements.join(' ').include?(name) })
    end

    it 'keeps a tie on one announcement when it exactly fits' do
      ending = ' tied for first in Quiz'
      names = ['a' * (255 - ending.length - ' and b'.length), 'b']

      expect(described_class.winner_announcements(names.map { |name| { 'name' => name } }, 'Quiz'))
        .to eq(["#{names.first} and b#{ending}"])
    end

    it 'starts a new announcement when one more name would not fit' do
      ending = ' tied for first in Quiz'
      names = ['a' * (255 - ending.length - ' and b'.length + 1), 'b']

      expect(described_class.winner_announcements(names.map { |name| { 'name' => name } }, 'Quiz'))
        .to eq(["#{names.first}#{ending}", "b#{ending}"])
    end
  end

  describe 'question answer window' do
    def close_question(num)
      $redis.hset(quiz_session.send(:question_key, num), 'closes_at', '1')
    end

    it 'gives players their time and the grace period, on the clock of Redis' do
      quiz_session.open_question(question_num, question_id, 30)

      closes_at = $redis.hget(quiz_session.send(:question_key, question_num), 'closes_at').to_f
      expect(closes_at - quiz_session.send(:redis_time)).to be_within(1).of(30 + QuizSession::ANSWER_GRACE_SECONDS)
    end

    it 'returns the question id while the question is open' do
      quiz_session.open_question(question_num, question_id, 30)

      expect(quiz_session.open_question_id(question_num)).to eq(question_id.to_s)
    end

    it 'returns nothing once the deadline has passed' do
      quiz_session.open_question(question_num, question_id, 30)

      close_question(question_num)

      expect(quiz_session.open_question_id(question_num)).to be_nil
    end

    it 'can restart the answer window, keeping the question' do
      quiz_session.open_question(question_num, question_id, 30)

      close_question(question_num)
      expect(quiz_session.open_question_id(question_num)).to be_nil

      quiz_session.restart_answer_window(question_num, 30)

      expect(quiz_session.open_question_id(question_num)).to eq(question_id.to_s)
    end

    it 'raises when Redis fails, so that the question is not published' do
      allow(quiz_session.instance_variable_get(:@redis)).to receive(:pipelined).and_raise(Redis::CannotConnectError)

      expect { quiz_session.open_question(question_num, question_id, 30) }.to raise_error(Redis::CannotConnectError)
    end

    it 'returns nothing for a question that was never opened' do
      expect(quiz_session.open_question_id(99)).to be_nil
    end

    it 'raises when Redis fails rather than reporting the question as closed' do
      allow(quiz_session.instance_variable_get(:@redis)).to receive(:hmget).and_raise(Redis::CannotConnectError)

      expect { quiz_session.open_question_id(question_num) }.to raise_error(Redis::CannotConnectError)
    end

    it 'points at the newest question when a question number is reopened' do
      quiz_session.open_question(question_num, question_id, 30)
      quiz_session.open_question(question_num, 789, 30)

      expect(quiz_session.open_question_id(question_num)).to eq('789')
    end

    it 'exposes the opened question to the difficulty update' do
      quiz_session.open_question(question_num, question_id, 30)

      expect(quiz_session.get_question_stats.first['qq_id']).to eq(question_id.to_s)
    end

    it 'forgets answers when the quiz data is cleaned up' do
      quiz_session.add_participant(user_id, user_name, user_login)
      quiz_session.open_question(question_num, question_id, 30)
      quiz_session.record_answer(question_num, user_id, score)
      quiz_session.cleanup_quiz_data
      quiz_session.add_participant(user_id, user_name, user_login)
      quiz_session.open_question(question_num, question_id, 30)

      expect(quiz_session.record_answer(question_num, user_id, score)).to eq(:graded)
    end
  end

  describe 'score management' do
    before do
      quiz_session.add_participant(user_id, user_name, user_login)
    end
    
    describe '#record_answer' do
      before do
        quiz_session.open_question(1, question_id, 30)
        quiz_session.open_question(2, question_id, 30)
      end

      def question_stats(num)
        $redis.hgetall("#{QuizSession::KEY_PREFIX}:#{quiz_id}:question:#{num}")
      end

      it 'saves the score and the question statistics together' do
        expect(quiz_session.record_answer(1, user_id, score)).to eq(:graded)

        expect(quiz_session.get_participants.first['score']).to eq(score.to_s)
        stats = question_stats(1)
        expect(stats['total_score']).to eq(score.to_s)
        expect(stats['answered']).to eq('1')
      end

      it 'accumulates scores across questions' do
        quiz_session.record_answer(1, user_id, 5)
        quiz_session.record_answer(2, user_id, 7)

        expect(quiz_session.get_participants.first['score']).to eq('12')
      end

      it 'uses up the answer but adds nothing for a zero score' do
        expect(quiz_session.record_answer(1, user_id, 0)).to eq(:graded)
        expect(quiz_session.record_answer(1, user_id, 10)).to eq(:duplicate)

        expect(quiz_session.get_participants.first['score']).to eq('0')
        expect(question_stats(1)).not_to include('total_score', 'answered')
      end

      it 'keeps only the first answer from each user' do
        quiz_session.add_participant(999, "Other User", "other@example.com")
        quiz_session.record_answer(1, user_id, 5)

        expect(quiz_session.record_answer(1, user_id, 10)).to eq(:duplicate)
        expect(quiz_session.record_answer(1, 999, 10)).to eq(:graded)
        expect(quiz_session.get_participants.find { |p| p['id'] == user_id.to_s }['score']).to eq('5')
        expect(question_stats(1)['answered']).to eq('2')
      end

      it 'refuses an answer after the question closes' do
        $redis.hset(quiz_session.send(:question_key, 1), 'closes_at', '1')

        expect(quiz_session.record_answer(1, user_id, 10)).to eq(:closed)
        expect(quiz_session.get_participants.first['score']).to eq('0')
      end

      it 'checks the deadline when the script runs, not when the answer was sent' do
        quiz_session.restart_answer_window(1, -(QuizSession::ANSWER_GRACE_SECONDS + 5))

        travel_to(1.hour.ago) do
          expect(quiz_session.record_answer(1, user_id, 10)).to eq(:closed)
        end
      end

      it 'refuses an answer to a question that was never opened' do
        expect(quiz_session.record_answer(99, user_id, 10)).to eq(:closed)
      end

      it 'raises when Redis fails, so the player can try again' do
        allow(quiz_session.instance_variable_get(:@redis)).to receive(:eval).and_raise(Redis::CannotConnectError)

        expect { quiz_session.record_answer(1, user_id, 10) }.to raise_error(Redis::CannotConnectError)
      end
    end
  end

  describe 'question statistics' do
    describe '#update_question_stats' do
      it 'stores question metadata' do
        result = quiz_session.update_question_stats(question_num, question_id, 50, 5)
        expect(result).to be true
        
        stats = quiz_session.get_question_stats
        expect(stats.length).to eq(1)
        
        question_data = stats.first
        expect(question_data['qq_id']).to eq(question_id.to_s)
        expect(question_data['total_score']).to eq('50')
        expect(question_data['answered']).to eq('5')
      end
      
      it 'works with minimal parameters' do
        result = quiz_session.update_question_stats(question_num, question_id)
        expect(result).to be true
        
        stats = quiz_session.get_question_stats
        expect(stats.first['qq_id']).to eq(question_id.to_s)
      end
    end
    
    describe '#get_question_stats' do
      it 'returns empty array when no questions' do
        expect(quiz_session.get_question_stats).to eq([])
      end
      
      it 'returns all question statistics' do
        quiz_session.update_question_stats(1, 100)
        quiz_session.update_question_stats(2, 200)
        
        stats = quiz_session.get_question_stats
        expect(stats.length).to eq(2)
      end
    end
  end

  describe 'quiz status management' do
    describe '#set_quiz_status and #get_quiz_status' do
      it 'sets and retrieves quiz status' do
        status = "In progress"
        result = quiz_session.set_quiz_status(status)
        expect(result).to be true
        
        retrieved_status = quiz_session.get_quiz_status
        expect(retrieved_status).to eq(status)
      end
      
      it 'stores additional metadata' do
        metadata = { start_time: Time.current.utc.iso8601, question_count: 25 }
        quiz_session.set_quiz_status("Started", metadata)
        
        all_metadata = quiz_session.get_quiz_metadata
        expect(all_metadata['status']).to eq("Started")
        expect(all_metadata['start_time']).to eq(metadata[:start_time])
        expect(all_metadata['question_count']).to eq(metadata[:question_count].to_s)
      end
    end
    
    describe '#quiz_in_progress?' do
      it 'returns false when no status set' do
        expect(quiz_session.quiz_in_progress?).to be false
      end
      
      it 'returns true when questions are actively running' do
        quiz_session.set_quiz_status("Question 1 in progress")
        expect(quiz_session.quiz_in_progress?).to be true
      end

      it 'returns false for chat period status' do
        quiz_session.set_quiz_status("In progress. Chat open. Wait for question.")
        expect(quiz_session.quiz_in_progress?).to be false
      end

      it 'returns false for initializing status' do
        quiz_session.set_quiz_status("In progress. Initializing...")
        expect(quiz_session.quiz_in_progress?).to be false
      end
      
      it 'returns false for finished status' do
        quiz_session.set_quiz_status(QuizSession::STATUS_FINISHED)
        expect(quiz_session.quiz_in_progress?).to be false
      end
    end
  end

  describe 'lock management' do
    describe '#lock_quiz and #unlock_quiz' do
      it 'acquires and releases lock successfully' do
        result = quiz_session.lock_quiz
        expect(result).to be true
        expect(quiz_session.quiz_locked?).to be true
        
        unlock_result = quiz_session.unlock_quiz
        expect(unlock_result).to be true
        expect(quiz_session.quiz_locked?).to be false
      end
      
      it 'cannot acquire lock when already locked' do
        quiz_session.lock_quiz
        
        # Try to acquire lock with different session
        other_session = QuizSession.new(quiz_id)
        result = other_session.lock_quiz
        expect(result).to be false
      end
      
      it 'uses custom duration' do
        result = quiz_session.lock_quiz(60) # 1 minute
        expect(result).to be true
        expect(quiz_session.quiz_locked?).to be true
      end
    end
    
    describe '#quiz_locked?' do
      it 'returns false when no lock exists' do
        expect(quiz_session.quiz_locked?).to be false
      end
      
      it 'returns true when lock exists' do
        quiz_session.lock_quiz
        expect(quiz_session.quiz_locked?).to be true
      end
    end
  end

  describe 'data cleanup' do
    before do
      # Set up test data
      quiz_session.add_participant(user_id, user_name, user_login)
      quiz_session.open_question(question_num, question_id, 30)
      quiz_session.record_answer(question_num, user_id, score)
      quiz_session.update_question_stats(question_num, question_id)
      quiz_session.set_quiz_status("Test status")
      quiz_session.lock_quiz
    end
    
    describe '#cleanup_quiz_data' do
      it 'removes all quiz-related data' do
        result = quiz_session.cleanup_quiz_data
        expect(result).to be true
        
        # Verify all data is cleaned up
        expect(quiz_session.get_participants).to be_empty
        expect(quiz_session.get_question_stats).to be_empty
        expect(quiz_session.get_quiz_status).to be_nil
        expect(quiz_session.quiz_locked?).to be false
      end
    end
    
    describe '#cleanup_legacy_data' do
      before do
        # Add some legacy format data
        $redis.hset("user-#{user_id}", "name", user_name)
        $redis.hset("qnum-#{question_num}", "qq_id", question_id)
      end
      
      it 'removes legacy format keys' do
        # Verify legacy data exists
        expect($redis.exists("user-#{user_id}")).to eq(1)
        expect($redis.exists("qnum-#{question_num}")).to eq(1)
        
        result = quiz_session.cleanup_legacy_data
        expect(result).to be true
        
        # Verify legacy data is removed
        expect($redis.exists("user-#{user_id}")).to eq(0)
        expect($redis.exists("qnum-#{question_num}")).to eq(0)
      end
    end
  end

  describe 'legacy compatibility' do
    describe '#legacy_participant_keys' do
      it 'returns legacy format participant keys' do
        $redis.hset("user-123", "name", "Test User")
        $redis.hset("user-456", "name", "Another User")
        
        keys = quiz_session.legacy_participant_keys
        expect(keys).to include("user-123", "user-456")
      end
    end
    
    describe '#legacy_question_keys' do
      it 'returns legacy format question keys' do
        $redis.hset("qnum-1", "qq_id", "100")
        $redis.hset("qnum-2", "qq_id", "200")
        
        keys = quiz_session.legacy_question_keys
        expect(keys).to include("qnum-1", "qnum-2")
      end
    end
  end

  describe 'error handling' do
    it 'handles Redis connection errors gracefully' do
      # Mock the Redis instance to raise an error
      allow($redis).to receive(:eval).and_raise(Redis::CannotConnectError)

      result = quiz_session.add_participant(user_id, user_name, user_login)
      expect(result).to be false
    end
    
    it 'returns empty array for get_participants on error' do
      allow($redis).to receive(:keys).and_raise(Redis::TimeoutError)
      
      result = quiz_session.get_participants
      expect(result).to eq([])
    end
    
    it 'returns nil for get_quiz_status on error' do
      allow($redis).to receive(:hget).and_raise(Redis::CommandError)
      
      result = quiz_session.get_quiz_status
      expect(result).to be_nil
    end
  end

  describe 'class methods' do
    describe '.cleanup_expired_data' do
      it 'removes expired quiz session keys' do
        # This is a maintenance method that would be called by a background job
        # We'll just verify it doesn't raise an error
        expect { QuizSession.cleanup_expired_data }.not_to raise_error
      end
    end
  end
end