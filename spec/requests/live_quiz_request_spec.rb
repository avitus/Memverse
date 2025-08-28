require 'rails_helper'

RSpec.describe "LiveQuiz Requests", type: :request do
  include Devise::Test::IntegrationHelpers
  
  let(:user) { FactoryBot.create(:user, translation: 'NIV') }
  let(:quiz_master) do
    admin_role = FactoryBot.create(:role, name: 'admin')
    user = FactoryBot.create(:user, name: 'Quiz Master', admin: true, translation: 'NIV')
    user.roles << admin_role
    user
  end
  let(:quiz) { FactoryBot.create(:quiz, user: quiz_master, name: 'Test Quiz', quiz_length: 1200) }
  let!(:quiz_questions) do
    # Stub update_length to prevent errors due to missing passage_translations
    allow_any_instance_of(Quiz).to receive(:update_length).and_return(true)
    [
      FactoryBot.create(:quiz_question, :reference, quiz: quiz),
      FactoryBot.create(:quiz_question, :reference, quiz: quiz),
      FactoryBot.create(:quiz_question, :mcq, quiz: quiz)
    ]
  end
  
  before do
    # Set up chat channel mock
    allow(ChatChannel).to receive(:find).and_return(
      double('ChatChannel', channel: "quiz-#{quiz.id}", status: 'open')
    )
    
    # Mock PubNub for testing
    allow(PN).to receive(:env).and_return({
      subscribe_key: 'test-subscribe-key',
      publish_key: 'test-publish-key'
    })
  end
  
  describe 'GET /live_quiz' do
    context 'when user has not chosen a translation' do
      let(:user_without_translation) { FactoryBot.create(:user, translation: nil) }
      
      it 'redirects to profile update page' do
        sign_in user_without_translation
        get "/live_quiz?quiz=#{quiz.id}"
        
        expect(response).to redirect_to(update_profile_path)
        follow_redirect!
        expect(response.body).to include('Please choose a translation')
      end
    end
    
    context 'when quiz is not ready' do
      let(:unready_quiz) { FactoryBot.create(:quiz, quiz_length: nil) }
      
      it 'redirects to root with notice' do
        sign_in user
        get "/live_quiz?quiz=#{unready_quiz.id}"
        
        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include('That quiz is not ready yet')
      end
    end
    
    context 'when quiz is ready' do
      before do
        # Mark quiz as running
        quiz_session = QuizSession.new(quiz.id)
        quiz_session.set_quiz_status(QuizSession::STATUS_IN_PROGRESS)
      end
      
      it 'displays quiz interface' do
        sign_in user
        get "/live_quiz?quiz=#{quiz.id}"
        
        expect(response).to have_http_status(:success)
        expect(response.body).to include(quiz.name)
        expect(response.body).to include('id="quiz-header"')
        expect(response.body).to include('id="live-quiz"')
        expect(response.body).to include('id="chat-window"')
        expect(response.body).to include('id="live-scoreboard"')
      end
      
      it 'shows correct number of question dots' do
        sign_in user
        get "/live_quiz?quiz=#{quiz.id}"
        
        expect(response).to have_http_status(:success)
        # Count the number of question dots
        expect(response.body.scan(/class="q-dot"/).count).to eq(quiz_questions.length)
      end
    end
  end
  
  describe 'POST /record_score' do
    it 'records score successfully' do
      sign_in user
      
      post '/record_score', params: {
        quiz_id: quiz.id,
        usr_id: user.id,
        usr_name: user.name_or_login,
        usr_login: user.login,
        question_id: quiz_questions.first.id,
        question_num: 1,
        score: 10
      }
      
      expect(response).to have_http_status(:ok)
    end
  end
  
  describe 'quiz timing' do
    before do
      # Mark quiz as running
      quiz_session = QuizSession.new(quiz.id)
      quiz_session.set_quiz_status(QuizSession::STATUS_IN_PROGRESS)
    end
    
    it 'calculates quiz duration correctly' do
      sign_in user
      get "/live_quiz?quiz=#{quiz.id}"
      
      expect(response).to have_http_status(:success)
      # Quiz length is 1200 seconds = 20 minutes
      expect(response.body).to include('20')
      expect(response.body).to include('00') # seconds
    end
    
    it 'uses default timing for knowledge quiz' do
      # Create a quiz with ID 1 (knowledge quiz)
      knowledge_quiz = Quiz.create!(
        id: 1, 
        user: quiz_master,
        name: 'Knowledge Quiz'
      )
      
      # Mark knowledge quiz as running
      quiz_session = QuizSession.new(1)
      quiz_session.set_quiz_status(QuizSession::STATUS_IN_PROGRESS)
      
      sign_in user
      get '/live_quiz?quiz=1'
      
      expect(response).to have_http_status(:success)
      expect(response.body).to include('20') # minutes
      expect(response.body).to include('25') # questions
    end
  end
end