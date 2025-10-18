require 'spec_helper'

describe Api::V1::LiveQuizController do

  before do
    allow(controller).to receive(:doorkeeper_token) {token}
  end

  let(:token) { double :acceptable? => true, :resource_owner_id => user.id }
  let(:user) { FactoryBot.create(:user) }
  let(:quiz_question) { FactoryBot.create(:quiz_question) }

  describe 'POST #record_score' do
    context "with valid score" do
      it "responds with 204 no content" do
        post :record_score, params: {
          usr_id: user.id,
          usr_name: user.name,
          usr_login: user.login,
          question_id: quiz_question.id,
          question_num: 1,
          score: 8,
          version: 1
        }, format: :json
        expect(response.status).to eq(204)
      end

      it "updates the quiz session with user score" do
        expect_any_instance_of(QuizSession).to receive(:add_participant).with(
          user.id, user.name, user.login
        )
        expect_any_instance_of(QuizSession).to receive(:update_score).with(
          user.id, 1, 8
        )
        expect_any_instance_of(QuizSession).to receive(:update_question_stats).with(
          1, quiz_question.id.to_s
        )

        post :record_score, params: {
          usr_id: user.id,
          usr_name: user.name,
          usr_login: user.login,
          question_id: quiz_question.id,
          question_num: 1,
          score: 8,
          version: 1
        }, format: :json
      end

      it "handles custom quiz_id" do
        quiz_id = 2
        expect(QuizSession).to receive(:new).with(quiz_id).and_call_original

        post :record_score, params: {
          quiz_id: quiz_id,
          usr_id: user.id,
          usr_name: user.name,
          usr_login: user.login,
          question_id: quiz_question.id,
          question_num: 1,
          score: 7,
          version: 1
        }, format: :json
      end
    end

    context "with false score (incorrect answer)" do
      it "does not update score" do
        expect_any_instance_of(QuizSession).not_to receive(:update_score)

        post :record_score, params: {
          usr_id: user.id,
          usr_name: user.name,
          usr_login: user.login,
          question_id: quiz_question.id,
          question_num: 1,
          score: "false",
          version: 1
        }, format: :json
      end

      it "logs the false score submission" do
        allow(Rails.logger).to receive(:info).and_call_original
        expect(Rails.logger).to receive(:info).with(/Score was submitted as false/)

        post :record_score, params: {
          usr_id: user.id,
          usr_name: user.name,
          usr_login: user.login,
          question_id: quiz_question.id,
          question_num: 1,
          score: "false",
          version: 1
        }, format: :json
      end
    end

    context "with zero score" do
      it "does not update score" do
        expect_any_instance_of(QuizSession).not_to receive(:update_score)

        post :record_score, params: {
          usr_id: user.id,
          usr_name: user.name,
          usr_login: user.login,
          question_id: quiz_question.id,
          question_num: 1,
          score: 0,
          version: 1
        }, format: :json
      end
    end

    context "without valid access token" do
      before do
        allow(controller).to receive(:doorkeeper_token) { nil }
      end

      it "responds with 401 when unauthorized" do
        post :record_score, params: {
          usr_id: user.id,
          usr_name: user.name,
          usr_login: user.login,
          question_id: quiz_question.id,
          question_num: 1,
          score: 8,
          version: 1
        }, format: :json
        expect(response.status).to eq(401)
      end
    end
  end

end
