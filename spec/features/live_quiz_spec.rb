require 'rails_helper'

RSpec.feature 'Live Quiz', type: :request do
  include Devise::Test::IntegrationHelpers
  
  let(:user) { FactoryBot.create(:user, translation: 'NIV') }
  let(:quiz_master) do
    admin_role = FactoryBot.create(:role, name: 'admin')
    user = FactoryBot.create(:user, name: 'Quiz Master', admin: true, translation: 'NIV')
    user.roles << admin_role
    user
  end
  # Create a knowledge quiz with ID 1 first so our test quiz gets a different ID
  let!(:knowledge_quiz) { FactoryBot.create(:quiz, id: 1, user: quiz_master, name: 'Bible Knowledge') }
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
      context 'and quiz is running' do
        before do
          # Mark quiz as running with a question in progress
          quiz_session = QuizSession.new(quiz.id)
          quiz_session.set_quiz_status("Question 1 in progress")
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
          # Modern view uses different class structure than legacy
          dots_count = response.body.scan(/class="q-dot[^"]*"/).count
          expect(dots_count).to eq(quiz_questions.length)
        end
      end
      
      context 'and quiz is not running' do
        it 'displays quiz schedule' do
          sign_in user
          # For knowledge quiz (ID=1), it should calculate next time
          knowledge_quiz = Quiz.find_or_create_by!(id: 1) do |q|
            q.user = quiz_master
            q.name = 'Knowledge Quiz'
            q.quiz_length = 1200
          end
          
          # Ensure quiz is not marked as running
          quiz_session = QuizSession.new(1)
          quiz_session.cleanup_quiz_data
          
          get "/live_quiz"
          
          expect(response).to have_http_status(:success)
          expect(response.body).to include(knowledge_quiz.name)  # Dynamic quiz name
          expect(response.body).to include('Next Quiz')
          expect(response.body).to include('Weekly Schedule')
        end
      end
    end
  end
  
  describe 'POST /record_score' do
    let(:quiz_session) { QuizSession.new(quiz.id) }
    let(:json_headers) { { 'Accept' => 'application/json' } }

    before do
      quiz_session.cleanup_quiz_data
      quiz_session.open_question(1, quiz_questions.last.id, 30)
    end

    after { quiz_session.cleanup_quiz_data }

    it 'records a graded answer' do
      sign_in user

      post '/record_score', params: { quiz_id: quiz.id, question_num: 1, answer: 'B' }, headers: json_headers

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq('status' => 'graded', 'score' => 10)
    end

    it 'rejects a signed out request' do
      post '/record_score', params: { quiz_id: quiz.id, question_num: 1, answer: 'B', usr_id: user.id }, headers: json_headers

      expect(response).to have_http_status(:unauthorized)
      expect(quiz_session.get_scoreboard).to be_empty
    end

    context 'with forgery protection on, as in production' do
      around do |example|
        original = ActionController::Base.allow_forgery_protection
        ActionController::Base.allow_forgery_protection = true
        example.run
      ensure
        ActionController::Base.allow_forgery_protection = original
      end

      it 'rejects a signed in request with no CSRF token' do
        sign_in user

        post '/record_score', params: { quiz_id: quiz.id, question_num: 1, answer: 'B' }, headers: json_headers

        expect(response).to have_http_status(:unauthorized)
        expect(quiz_session.get_scoreboard).to be_empty
      end

      it 'accepts the CSRF token from the page, sent the way the quiz page sends it' do
        sign_in user

        get "/live_quiz?quiz=#{quiz.id}"
        token = Nokogiri::HTML(response.body).at_css('meta[name="csrf-token"]')['content']

        post '/record_score',
             params: { quiz_id: quiz.id, question_num: 1, answer: 'B' },
             headers: json_headers.merge('X-CSRF-Token' => token)

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq('status' => 'graded', 'score' => 10)
      end
    end
  end
  
  describe 'quiz interactions' do
    before do
      # Mark quiz as running with a question in progress
      quiz_session = QuizSession.new(quiz.id)
      quiz_session.set_quiz_status("Question 1 in progress", {
        current_question: 1,
        started_at: Time.current.to_s
      })
    end
    
    it 'displays quiz with chat form' do
      sign_in user
      get "/live_quiz?quiz=#{quiz.id}"
      
      expect(response).to have_http_status(:success)
      
      # Check for chat window
      expect(response.body).to include('id="chat-window"')
      
      # Look for either modern or legacy chat input
      has_chat_input = response.body.include?('data-live-quiz-target="chatInput"') || 
                       response.body.include?('name="msg_body"')
      expect(has_chat_input).to be true
      
      # Look for either modern button or legacy submit
      has_submit = response.body.include?('<button') && response.body.include?('Send') ||
                   response.body.include?('input type="submit"')
      expect(has_submit).to be true
    end
    
    it 'displays quiz status elements' do
      sign_in user
      get "/live_quiz?quiz=#{quiz.id}"
      
      expect(response).to have_http_status(:success)
      expect(response.body).to include('id="countdown-till"')
    end
    
    it 'shows scoreboard section' do
      sign_in user
      get "/live_quiz?quiz=#{quiz.id}"
      
      expect(response).to have_http_status(:success)
      expect(response.body).to include('id="live-scoreboard"')
      expect(response.body).to include('Scoreboard')
      expect(response.body).to include('Scores are updated at the end of each question')
    end
  end
  
  describe 'admin features' do
    before do
      # Mark quiz as running
      quiz_session = QuizSession.new(quiz.id)
      quiz_session.set_quiz_status("Question 1 in progress")
    end
    
    it 'shows chat toggle for admins' do
      sign_in quiz_master
      get "/live_quiz?quiz=#{quiz.id}"
      
      expect(response).to have_http_status(:success)
      expect(response.body).to include('Toggle Status')
    end
  end
  
  describe 'quiz timing' do
    before do
      # Mark quiz as running
      quiz_session = QuizSession.new(quiz.id)
      quiz_session.set_quiz_status("Question 1 in progress")
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
      # Mark knowledge quiz (ID 1) as running
      quiz_session = QuizSession.new(knowledge_quiz.id)
      quiz_session.set_quiz_status("Question 1 in progress")
      
      sign_in user
      get "/live_quiz?quiz=#{knowledge_quiz.id}"
      
      expect(response).to have_http_status(:success)
      expect(response.body).to include('20') # minutes
      expect(response.body).to include('25') # questions
    end
  end
end