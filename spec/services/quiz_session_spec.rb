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
      it 'returns participants sorted by score descending' do
        # Add participants with different scores
        quiz_session.add_participant(1, "User 1", "user1@example.com")
        quiz_session.add_participant(2, "User 2", "user2@example.com")
        quiz_session.add_participant(3, "User 3", "user3@example.com")
        
        # Update scores
        quiz_session.update_score(1, 1, 5)
        quiz_session.update_score(2, 1, 10)
        quiz_session.update_score(3, 1, 7)
        
        scoreboard = quiz_session.get_scoreboard
        expect(scoreboard.length).to eq(3)
        expect(scoreboard[0]['name']).to eq("User 2")  # Highest score
        expect(scoreboard[0]['score']).to eq('10')
        expect(scoreboard[1]['name']).to eq("User 3")  # Second highest
        expect(scoreboard[1]['score']).to eq('7')
        expect(scoreboard[2]['name']).to eq("User 1")  # Lowest score
        expect(scoreboard[2]['score']).to eq('5')
      end
    end
  end

  describe 'score management' do
    before do
      quiz_session.add_participant(user_id, user_name, user_login)
    end
    
    describe '#update_score' do
      it 'updates user score successfully' do
        result = quiz_session.update_score(user_id, question_num, score)
        expect(result).to be true
        
        participants = quiz_session.get_participants
        expect(participants.first['score']).to eq(score.to_s)
      end
      
      it 'accumulates multiple scores' do
        quiz_session.update_score(user_id, 1, 5)
        quiz_session.update_score(user_id, 2, 7)
        
        participants = quiz_session.get_participants
        expect(participants.first['score']).to eq('12')
      end
      
      it 'returns false for zero score' do
        result = quiz_session.update_score(user_id, question_num, 0)
        expect(result).to be false
      end
      
      it 'returns false for negative score' do
        result = quiz_session.update_score(user_id, question_num, -5)
        expect(result).to be false
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
      quiz_session.update_score(user_id, question_num, score)
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
      allow($redis).to receive(:pipelined).and_raise(Redis::CannotConnectError)
      
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