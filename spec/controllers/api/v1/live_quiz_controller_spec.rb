require 'spec_helper'

describe Api::V1::LiveQuizController do

  before do
    allow(controller).to receive(:doorkeeper_token) {token}
  end

  let(:token) { double :acceptable? => true, :resource_owner_id => user.id }
  let(:user) { FactoryBot.create(:user, translation: 'NIV') }
  let(:quiz_question) { FactoryBot.create(:quiz_question, :mcq) }
  let(:quiz_id) { 1 }
  let(:quiz_session) { QuizSession.new(quiz_id) }

  def scoreboard_score(user_id)
    quiz_session.get_scoreboard.find { |entry| entry['id'] == user_id.to_s }&.fetch('score').to_i
  end

  describe 'POST #record_score' do
    before do
      quiz_session.cleanup_quiz_data
      quiz_session.open_question(1, quiz_question.id, 30)
    end

    after { quiz_session.cleanup_quiz_data }

    context "with a right answer" do
      it "grades it on the server and returns the score" do
        post :record_score, params: { question_num: 1, answer: 'B', version: 1 }, format: :json

        expect(response.status).to eq(200)
        expect(JSON.parse(response.body)).to eq('status' => 'graded', 'score' => 10)
        expect(scoreboard_score(user.id)).to eq(10)
      end

      it "uses the requested quiz" do
        other_session = QuizSession.new(2)
        other_session.cleanup_quiz_data
        other_session.open_question(1, quiz_question.id, 30)

        post :record_score, params: { quiz_id: 2, question_num: 1, answer: 'B', version: 1 }, format: :json

        expect(other_session.get_scoreboard.first['id']).to eq(user.id.to_s)
        expect(quiz_session.get_scoreboard).to be_empty
        other_session.cleanup_quiz_data
      end
    end

    context "with a wrong answer" do
      it "lists the user without points" do
        post :record_score, params: { question_num: 1, answer: 'A', version: 1 }, format: :json

        expect(JSON.parse(response.body)).to eq('status' => 'graded', 'score' => 0)
        expect(scoreboard_score(user.id)).to eq(0)
      end
    end

    context "with values a client should not control" do
      it "ignores a score sent by the client" do
        post :record_score, params: { question_num: 1, answer: 'A', score: 10, version: 1 }, format: :json

        expect(scoreboard_score(user.id)).to eq(0)
      end

      it "scores the token owner rather than a user id sent by the client" do
        victim = FactoryBot.create(:user)

        post :record_score, params: { question_num: 1, answer: 'B', usr_id: victim.id, version: 1 }, format: :json

        expect(scoreboard_score(victim.id)).to eq(0)
        expect(scoreboard_score(user.id)).to eq(10)
      end
    end

    context "with a repeated answer" do
      it "counts only the first" do
        post :record_score, params: { question_num: 1, answer: 'A', version: 1 }, format: :json
        post :record_score, params: { question_num: 1, answer: 'B', version: 1 }, format: :json

        expect(JSON.parse(response.body)).to eq('status' => 'duplicate')
        expect(scoreboard_score(user.id)).to eq(0)
      end
    end

    context "when the user has not chosen a translation" do
      before { user.update!(translation: nil) }

      it "responds with 422 and records nothing" do
        post :record_score, params: { question_num: 1, answer: 'B', version: 1 }, format: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to include('error' => 'unprocessable_entity')
        expect(quiz_session.get_scoreboard.map { |entry| entry['id'] }).not_to include(user.id.to_s)
      end
    end

    context "from an old app that sends its own score and no answer" do
      it "responds with 400 asking for an update, and records nothing" do
        post :record_score, params: { question_num: 1, question_id: quiz_question.id, score: 10, usr_id: user.id, version: 1 }, format: :json

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)['message']).to include('Please update')
        expect(quiz_session.get_scoreboard).to eq([])
      end
    end

    context "with a question number that is not a positive integer" do
      [nil, '', 'abc', '1x', '0', '-1', '1.5'].each do |question_num|
        it "responds with 400 for #{question_num.inspect} and records nothing" do
          post :record_score, params: { question_num: question_num, answer: 'B', version: 1 }, format: :json

          expect(response).to have_http_status(:bad_request)
          expect(JSON.parse(response.body)).to include('error' => 'bad_request')
          expect(quiz_session.get_scoreboard).to eq([])
        end
      end

      it "accepts a number sent as JSON" do
        post :record_score, params: { question_num: 1, answer: 'B', version: 1 }, as: :json

        expect(response).to have_http_status(:ok)
      end
    end

    context "when the question is not open" do
      it "reports it as closed" do
        post :record_score, params: { question_num: 2, answer: 'B', version: 1 }, format: :json

        expect(JSON.parse(response.body)).to eq('status' => 'closed')
      end
    end

    context "without valid access token" do
      before do
        allow(controller).to receive(:doorkeeper_token) { nil }
      end

      it "responds with 401 and records nothing" do
        post :record_score, params: { question_num: 1, answer: 'B', version: 1 }, format: :json

        expect(response.status).to eq(401)
        expect(quiz_session.get_scoreboard).to be_empty
      end
    end
  end

end
