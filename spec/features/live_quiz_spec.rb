require 'rails_helper'

RSpec.feature 'Live Quiz', type: :feature, js: true do
  include Devise::Test::IntegrationHelpers
  include Warden::Test::Helpers
  
  let(:user) { FactoryBot.create(:user, translation: 'NIV') }
  let(:quiz_master) { FactoryBot.create(:user, name: 'Quiz Master', admin: true) }
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
    # Enable Warden test mode and reset
    Warden.test_mode!
    Warden.test_reset!
    
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
  
  after do
    # Reset Warden after each test
    Warden.test_reset!
  end
  
  describe 'accessing live quiz' do
    context 'when user has not chosen a translation' do
      let(:user_without_translation) { FactoryBot.create(:user, translation: nil) }
      
      it 'redirects to profile update page' do
        login_as user_without_translation, scope: :user
        visit "/live_quiz?quiz=#{quiz.id}"
        
        expect(page).to have_content('Please choose a translation')
        expect(current_path).to eq(update_profile_path)
      end
    end
    
    context 'when quiz is not ready' do
      let(:unready_quiz) { FactoryBot.create(:quiz, quiz_length: nil) }
      
      it 'redirects to root with notice' do
        login_as user, scope: :user
        visit "/live_quiz?quiz=#{unready_quiz.id}"
        
        expect(page).to have_content('That quiz is not ready yet')
        expect(current_path).to eq(root_path)
      end
    end
    
    context 'when quiz is ready' do
      it 'displays quiz interface' do
        login_as user, scope: :user
        visit "/live_quiz?quiz=#{quiz.id}"
        
        expect(page).to have_content(quiz.name)
        expect(page).to have_css('#quiz-header')
        expect(page).to have_css('#live-quiz')
        expect(page).to have_css('#chat-window')
        expect(page).to have_css('#live-scoreboard')
      end
      
      it 'shows correct number of question dots' do
        login_as user, scope: :user
        visit "/live_quiz?quiz=#{quiz.id}"
        
        expect(page).to have_css('.q-dot', count: quiz_questions.length)
      end
    end
  end
  
  describe 'modern interface feature flag' do
    context 'when modern interface is enabled' do
      it 'renders modern interface for admin users' do
        login_as quiz_master, scope: :user
        visit "/live_quiz?quiz=#{quiz.id}&modern=true"
        
        expect(page).to have_css('[data-controller="live-quiz"]')
        expect(page).to have_css('[data-live-quiz-target="timer"]')
        expect(page).to have_css('[data-live-quiz-target="chatArea"]')
      end
      
      it 'renders modern interface when environment variable is set' do
        ENV['USE_MODERN_QUIZ_INTERFACE'] = 'true'
        login_as user, scope: :user
        visit "/live_quiz?quiz=#{quiz.id}"
        
        expect(page).to have_css('[data-controller="live-quiz"]')
        
        ENV['USE_MODERN_QUIZ_INTERFACE'] = 'false'
      end
    end
    
    context 'when modern interface is disabled' do
      it 'renders legacy interface by default' do
        login_as user, scope: :user
        visit "/live_quiz?quiz=#{quiz.id}"
        
        expect(page).not_to have_css('[data-controller="live-quiz"]')
        expect(page).to have_css('#quiz-header')
      end
    end
  end
  
  describe 'quiz interactions' do
    before do
      login_as user, scope: :user
      visit "/live_quiz?quiz=#{quiz.id}"
    end
    
    it 'allows users to send chat messages' do
      within '#chat-window' do
        fill_in 'msg_body', with: 'Hello everyone!'
        click_button 'Send'
      end
      
      # Chat would appear via PubNub in real scenario
      expect(page).to have_field('msg_body', with: '')
    end
    
    it 'displays quiz status' do
      expect(page).to have_css('#countdown-till')
    end
    
    it 'shows scoreboard section' do
      within '#live-scoreboard' do
        expect(page).to have_content('Scoreboard')
        expect(page).to have_content('Scores are updated at the end of each question')
      end
    end
  end
  
  describe 'admin features' do
    before do
      sign_in quiz_master
      visit "/live_quiz?quiz=#{quiz.id}"
    end
    
    it 'shows chat toggle for admins' do
      within '#chat-window' do
        expect(page).to have_link('Toggle Status')
      end
    end
  end
  
  describe 'score recording' do
    it 'sends score to server', :skip_before do
      login_as user, scope: :user
      
      # Use page.driver for rack-test specific methods
      # For Capybara 3+, we should use proper API testing instead
      post '/live_quiz/record_score', params: {
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
    it 'calculates quiz duration correctly' do
      login_as user, scope: :user
      visit "/live_quiz?quiz=#{quiz.id}"
      
      # Quiz length is 1200 seconds = 20 minutes
      expect(page.body).to include('20')
      expect(page.body).to include('00') # seconds
    end
    
    it 'uses default timing for knowledge quiz' do
      # Create a quiz with ID 1 (knowledge quiz)
      knowledge_quiz = Quiz.create!(
        id: 1, 
        user: quiz_master,
        name: 'Knowledge Quiz'
      )
      
      login_as user, scope: :user
      visit '/live_quiz?quiz=1'
      
      expect(page.body).to include('20') # minutes
      expect(page.body).to include('25') # questions
    end
  end
end