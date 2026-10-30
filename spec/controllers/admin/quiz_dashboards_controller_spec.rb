require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe Admin::QuizDashboardsController, type: :controller do
  let(:admin_user) { FactoryBot.create(:user, admin: true) }
  let(:quiz) { FactoryBot.create(:quiz, user: admin_user, start_time: 2.days.from_now) }

  around do |example|
    Sidekiq::Testing.fake! { example.run }
  end

  before { ScheduledQuiz.jobs.clear; KnowledgeQuiz.jobs.clear }

  describe 'POST #start' do
    it 'is admin only' do
      sign_in FactoryBot.create(:user, admin: false)
      post :start, params: { id: quiz.id }
      expect(response).to redirect_to(root_path)
      expect(ScheduledQuiz.jobs).to be_empty
    end

    context 'as an admin' do
      before { sign_in admin_user }

      it 'moves a custom quiz into the worker\'s one-minute window and enqueues ScheduledQuiz' do
        post :start, params: { id: quiz.id }

        expect(response).to redirect_to(admin_quiz_dashboard_path(quiz))
        expect(quiz.reload.start_time).to be_between(Time.current, 1.minute.from_now)
        expect(ScheduledQuiz.jobs.map { |job| job['args'] }).to eq([[quiz.id]])
        expect(KnowledgeQuiz.jobs).to be_empty
      end

      it 'enqueues KnowledgeQuiz for the knowledge quiz without touching its schedule' do
        knowledge_quiz = FactoryBot.create(:quiz, id: 1, user: admin_user, start_time: 2.days.from_now)

        expect { post :start, params: { id: knowledge_quiz.id } }.not_to change { knowledge_quiz.reload.start_time }
        expect(KnowledgeQuiz.jobs.size).to eq(1)
        expect(ScheduledQuiz.jobs).to be_empty
      end
    end
  end
end
