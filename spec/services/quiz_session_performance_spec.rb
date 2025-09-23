require 'rails_helper'

RSpec.describe QuizSession, type: :service do
  describe 'Performance comparison: KEYS vs Sets' do
    let(:quiz_id) { 1 }
    let(:quiz_session) { QuizSession.new(quiz_id) }

    before do
      # Clean up any existing data
      quiz_session.cleanup_quiz_data
    end

    after do
      # Clean up test data
      quiz_session.cleanup_quiz_data
    end

    context 'with many participants' do
      before do
        # Add 100 participants
        100.times do |i|
          quiz_session.add_participant(i + 1, "User #{i + 1}", "user#{i + 1}@example.com")
        end

        # Update scores for 25 questions
        25.times do |q_num|
          100.times do |user_id|
            score = rand(0..10)
            quiz_session.update_score(user_id + 1, q_num + 1, score) if score > 0
          end

          # Update question stats
          quiz_session.update_question_stats(q_num + 1, 1000 + q_num)
        end
      end

      it 'retrieves scoreboard efficiently' do
        # Warm up
        quiz_session.get_scoreboard

        # Measure time for scoreboard retrieval
        start_time = Time.now
        scoreboard = quiz_session.get_scoreboard
        end_time = Time.now

        elapsed = end_time - start_time

        expect(scoreboard).not_to be_empty
        expect(scoreboard.size).to eq(100)
        expect(elapsed).to be < 0.1 # Should complete in under 100ms

        puts "Scoreboard retrieval time: #{(elapsed * 1000).round(2)}ms"
      end

      it 'retrieves participants efficiently' do
        # Warm up
        quiz_session.get_participants

        # Measure time
        start_time = Time.now
        participants = quiz_session.get_participants
        end_time = Time.now

        elapsed = end_time - start_time

        expect(participants).not_to be_empty
        expect(participants.size).to eq(100)
        expect(elapsed).to be < 0.1 # Should complete in under 100ms

        puts "Participants retrieval time: #{(elapsed * 1000).round(2)}ms"
      end

      it 'retrieves question stats efficiently' do
        # Warm up
        quiz_session.get_question_stats

        # Measure time
        start_time = Time.now
        questions = quiz_session.get_question_stats
        end_time = Time.now

        elapsed = end_time - start_time

        expect(questions).not_to be_empty
        expect(questions.size).to eq(25)
        expect(elapsed).to be < 0.05 # Should complete in under 50ms

        puts "Question stats retrieval time: #{(elapsed * 1000).round(2)}ms"
      end

      it 'handles cleanup efficiently' do
        # Measure cleanup time
        start_time = Time.now
        result = quiz_session.cleanup_quiz_data
        end_time = Time.now

        elapsed = end_time - start_time

        expect(result).to be true
        expect(elapsed).to be < 0.2 # Should complete in under 200ms

        # Verify data is cleaned up
        expect(quiz_session.get_scoreboard).to be_empty
        expect(quiz_session.get_participants).to be_empty
        expect(quiz_session.get_question_stats).to be_empty

        puts "Cleanup time: #{(elapsed * 1000).round(2)}ms"
      end
    end

    context 'stress test with very large dataset' do
      it 'performs well with 500 participants and 25 questions' do
        # Add 500 participants
        500.times do |i|
          quiz_session.add_participant(i + 1, "User #{i + 1}", "user#{i + 1}@example.com")
        end

        # Simulate 6 questions (where the stall happens)
        6.times do |q_num|
          500.times do |user_id|
            score = rand(0..10)
            quiz_session.update_score(user_id + 1, q_num + 1, score) if score > 0
          end
        end

        # This is where the stall would happen with KEYS command
        start_time = Time.now
        scoreboard = quiz_session.get_scoreboard
        end_time = Time.now

        elapsed = end_time - start_time

        expect(scoreboard.size).to eq(500)
        expect(elapsed).to be < 0.3 # Should still be fast even with 500 users

        puts "Large dataset scoreboard retrieval: #{(elapsed * 1000).round(2)}ms"
      end
    end
  end

  describe 'Functional verification' do
    let(:quiz_id) { 1 }
    let(:quiz_session) { QuizSession.new(quiz_id) }

    before do
      quiz_session.cleanup_quiz_data
    end

    after do
      quiz_session.cleanup_quiz_data
    end

    it 'correctly tracks and sorts participants by score' do
      # Add participants
      quiz_session.add_participant(1, "Alice", "alice@example.com")
      quiz_session.add_participant(2, "Bob", "bob@example.com")
      quiz_session.add_participant(3, "Charlie", "charlie@example.com")

      # Update scores
      quiz_session.update_score(1, 1, 10) # Alice: 10
      quiz_session.update_score(2, 1, 8)  # Bob: 8
      quiz_session.update_score(3, 1, 9)  # Charlie: 9

      quiz_session.update_score(1, 2, 7)  # Alice: 17
      quiz_session.update_score(2, 2, 10) # Bob: 18
      quiz_session.update_score(3, 2, 5)  # Charlie: 14

      scoreboard = quiz_session.get_scoreboard

      expect(scoreboard[0]['name']).to eq("Bob")
      expect(scoreboard[0]['score']).to eq("18")
      expect(scoreboard[1]['name']).to eq("Alice")
      expect(scoreboard[1]['score']).to eq("17")
      expect(scoreboard[2]['name']).to eq("Charlie")
      expect(scoreboard[2]['score']).to eq("14")
    end

    it 'correctly tracks question statistics' do
      quiz_session.add_participant(1, "Alice", "alice@example.com")
      quiz_session.add_participant(2, "Bob", "bob@example.com")

      # Question 1
      quiz_session.update_question_stats(1, 1001)
      quiz_session.update_score(1, 1, 10)
      quiz_session.update_score(2, 1, 8)

      # Question 2
      quiz_session.update_question_stats(2, 1002)
      quiz_session.update_score(1, 2, 7)
      quiz_session.update_score(2, 2, 0) # Bob didn't answer

      stats = quiz_session.get_question_stats

      q1_stats = stats.find { |s| s['qq_id'] == '1001' }
      q2_stats = stats.find { |s| s['qq_id'] == '1002' }

      expect(q1_stats['total_score']).to eq('18')
      expect(q1_stats['answered']).to eq('2')

      expect(q2_stats['total_score']).to eq('7')
      expect(q2_stats['answered']).to eq('1')
    end
  end
end