require 'rails_helper'

RSpec.describe QuizAnswerSubmission do
  let(:quiz_id) { 77 }
  let(:session) { QuizSession.new(quiz_id) }
  let(:user) { FactoryBot.create(:user, translation: 'NIV') }
  let(:question) { FactoryBot.create(:quiz_question, :mcq) }

  before { session.cleanup_quiz_data }
  after { session.cleanup_quiz_data }

  def submit(answer, question_num: 1, as: user)
    described_class.call(user: as, quiz_id: quiz_id, question_num: question_num, answer: answer)
  end

  def score_of(a_user)
    session.get_scoreboard.find { |entry| entry['id'] == a_user.id.to_s }&.fetch('score').to_i
  end

  context 'while the question is open' do
    before { session.open_question(1, question.id, 30) }

    it 'scores a right answer for the given user' do
      result = submit('B')

      expect(result.status).to eq(:graded)
      expect(result.score).to eq(10)
      expect(score_of(user)).to eq(10)
    end

    it 'records a wrong answer without points' do
      result = submit('A')

      expect(result.status).to eq(:graded)
      expect(result.score).to eq(0)
      expect(score_of(user)).to eq(0)
      expect(session.get_scoreboard.map { |entry| entry['id'] }).to include(user.id.to_s)
    end

    it 'counts only the first answer from a user' do
      submit('A')
      result = submit('B')

      expect(result.status).to eq(:duplicate)
      expect(result.score).to be_nil
      expect(score_of(user)).to eq(0)
    end

    it 'does not let a repeated right answer add points' do
      2.times { submit('B') }

      expect(score_of(user)).to eq(10)
    end

    it 'lets another user answer the same question' do
      other = FactoryBot.create(:user)
      submit('B')
      submit('B', as: other)

      expect(score_of(user)).to eq(10)
      expect(score_of(other)).to eq(10)
    end

    it 'stores the name and login from the user record' do
      submit('B')
      entry = session.get_scoreboard.first

      expect(entry['name']).to eq(user.name_or_login)
      expect(entry['login']).to eq(user.login)
    end
  end

  context 'when the question is closed' do
    it 'does not score an answer after the deadline' do
      session.open_question(1, question.id, 30)

      travel_to(1.hour.from_now) do
        result = submit('B')

        expect(result.status).to eq(:closed)
        expect(score_of(user)).to eq(0)
      end
    end

    it 'still accepts an answer inside the grace period' do
      session.open_question(1, question.id, 30)

      travel_to((30 + QuizSession::ANSWER_GRACE_SECONDS - 1).seconds.from_now) do
        expect(submit('B').status).to eq(:graded)
      end
    end

    it 'does not score a question the quiz never asked' do
      result = submit('B', question_num: 9)

      expect(result.status).to eq(:closed)
      expect(score_of(user)).to eq(0)
    end

    it 'does not score a question number with no question stored behind it' do
      session.open_question(1, -1, 30)

      expect(submit('B').status).to eq(:closed)
    end
  end

  context 'without an answer' do
    it 'lists the participant with no points' do
      session.open_question(1, question.id, 30)
      result = submit(nil)

      expect(result.status).to eq(:unanswered)
      expect(score_of(user)).to eq(0)
      expect(session.get_scoreboard.map { |entry| entry['id'] }).to include(user.id.to_s)
    end

    it 'does not use up the one answer the user is allowed' do
      session.open_question(1, question.id, 30)
      submit(nil)

      expect(submit('B').score).to eq(10)
    end
  end
end
