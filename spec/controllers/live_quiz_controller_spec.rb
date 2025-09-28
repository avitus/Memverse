require 'rails_helper'

RSpec.describe LiveQuizController, type: :controller do
  include Devise::Test::ControllerHelpers
  
  let(:user) { FactoryBot.create(:user, translation: 'NIV') }
  let(:admin_user) { FactoryBot.create(:user, admin: true, translation: 'NIV') }
  let(:quiz) { FactoryBot.create(:quiz, name: 'Test Quiz', quiz_length: 1200) }
  
  before do
    # Mock ChatChannel
    allow(ChatChannel).to receive(:find).and_return(
      double('ChatChannel', channel: "quiz-#{quiz.id}", status: 'open')
    )
    
    # Mock PubNub
    allow(PN).to receive(:env).and_return({
      subscribe_key: 'test-key',
      publish_key: 'test-key'
    })
  end
  
  describe 'GET #live_quiz' do
    context 'when user is not signed in' do
      it 'redirects to sign in' do
        get :live_quiz, params: { quiz: quiz.id }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    
    context 'when user has no translation' do
      let(:user_no_translation) { FactoryBot.create(:user, translation: nil) }
      
      it 'redirects to profile update' do
        sign_in user_no_translation
        get :live_quiz, params: { quiz: quiz.id }
        expect(response).to redirect_to(update_profile_path)
        expect(flash[:notice]).to eq('Please choose a translation and then return to the quiz.')
      end
    end
    
    context 'quiz running status and next scheduled time' do
      let(:quiz_session) { instance_double(QuizSession) }
      
      before do
        sign_in user
        allow(QuizSession).to receive(:new).and_return(quiz_session)
      end
      
      context 'when quiz is not running' do
        before do
          allow(quiz_session).to receive(:quiz_in_progress?).and_return(false)
        end
        
        it 'calculates next scheduled quiz time for knowledge quiz (ID=1)' do
          quiz1 = Quiz.create!(id: 1, user: user, name: 'Knowledge Quiz')
          
          travel_to Time.parse('2025-01-06 10:00:00 UTC') do # Monday
            get :live_quiz
            
            expect(assigns(:quiz_running)).to eq(false)
            expect(assigns(:next_quiz_time)).to be_present
            expect(assigns(:next_quiz_time).wday).to eq(2) # Tuesday
            expect(assigns(:next_quiz_time).hour).to eq(17)
            expect(assigns(:next_quiz_time).zone).to eq('UTC')
          end
        end
        
        it 'uses quiz start_time for non-knowledge quizzes' do
          future_time = 2.days.from_now
          quiz.update!(start_time: future_time)
          
          get :live_quiz, params: { quiz: quiz.id }
          
          expect(assigns(:quiz_running)).to eq(false)
          expect(assigns(:next_quiz_time)).to eq(quiz.start_time)
        end
        
        it 'does not set next_quiz_time if start_time is in the past' do
          past_time = 2.days.ago
          quiz.update!(start_time: past_time)
          
          get :live_quiz, params: { quiz: quiz.id }
          
          expect(assigns(:quiz_running)).to eq(false)
          expect(assigns(:next_quiz_time)).to be_nil
        end
      end
      
      context 'when quiz is running' do
        before do
          allow(quiz_session).to receive(:quiz_in_progress?).and_return(true)
        end
        
        it 'does not calculate next quiz time' do
          get :live_quiz, params: { quiz: quiz.id }
          
          expect(assigns(:quiz_running)).to eq(true)
          expect(assigns(:next_quiz_time)).to be_nil
        end
      end
    end
    
    context 'when quiz is not ready' do
      let(:unready_quiz) { FactoryBot.create(:quiz, quiz_length: nil) }
      
      it 'redirects to root with notice' do
        sign_in user
        get :live_quiz, params: { quiz: unready_quiz.id }
        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to eq('That quiz is not ready yet.')
      end
    end
    
    context 'when quiz is ready' do
      it 'renders the quiz page' do
        sign_in user
        get :live_quiz, params: { quiz: quiz.id }
        expect(response).to be_successful
        expect(assigns(:quiz)).to eq(quiz)
        expect(assigns(:minutes)).to eq(20)
        expect(assigns(:seconds)).to eq(0)
      end
      
      it 'sets default quiz ID to 1 when no param' do
        sign_in user
        quiz1 = Quiz.create!(id: 1, user: user, name: 'Knowledge Quiz')
        get :live_quiz
        expect(assigns(:quiz)).to eq(quiz1)
      end
    end
  end
  
  describe 'POST #record_score' do
    it 'records score successfully' do
      quiz_session = instance_double(QuizSession)
      expect(QuizSession).to receive(:new).with(quiz.id.to_s).and_return(quiz_session)
      expect(quiz_session).to receive(:add_participant).with(user.id, user.name_or_login, user.login)
      expect(quiz_session).to receive(:update_score).with(user.id, 1, 10)
      expect(quiz_session).to receive(:update_question_stats).with(1, '123')
      
      post :record_score, params: {
        quiz_id: quiz.id,
        usr_id: user.id,
        usr_name: user.name_or_login,
        usr_login: user.login,
        question_id: '123',
        question_num: 1,
        score: '10'
      }
      
      expect(response).to have_http_status(:ok)
    end
    
    it 'handles false score gracefully' do
      post :record_score, params: {
        quiz_id: quiz.id,
        usr_id: user.id,
        usr_name: user.name_or_login,
        usr_login: user.login,
        question_id: '123',
        question_num: 1,
        score: 'false'
      }
      
      expect(response).to have_http_status(:ok)
    end
    
    it 'handles zero score' do
      post :record_score, params: {
        quiz_id: quiz.id,
        usr_id: user.id,
        usr_name: user.name_or_login,
        usr_login: user.login,
        question_id: '123',
        question_num: 1,
        score: '0'
      }
      
      expect(response).to have_http_status(:ok)
    end
  end
  
  describe 'GET #till_start' do
    context 'when quiz has not started' do
      let(:future_quiz) { FactoryBot.create(:quiz, start_time: 1.hour.from_now) }
      
      it 'returns time until quiz starts' do
        get :till_start, params: { id: future_quiz.id, format: :json }
        
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('time')
        expect(json_response['time']).to match(/^\+\d+h \+\d+m \+\d+s$/)
      end
    end
    
    context 'when quiz is in progress' do
      let(:current_quiz) { FactoryBot.create(:quiz, start_time: 10.minutes.ago) }

      before do
        # Use QuizSession service to set the status properly
        quiz_session = QuizSession.new(current_quiz.id)
        quiz_session.set_quiz_status("In progress. Wait for question.")
      end

      after do
        # Clean up using QuizSession service
        quiz_session = QuizSession.new(current_quiz.id)
        quiz_session.cleanup_quiz_data
      end

      it 'returns quiz status' do
        get :till_start, params: { id: current_quiz.id, format: :json }

        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('status')
        expect(json_response['status']).to include('progress')
      end
    end
    
    context 'when quiz is finished' do
      let(:past_quiz) { FactoryBot.create(:quiz, start_time: 2.hours.ago) }
      
      it 'returns finished status' do
        # Ensure no Redis entry exists for this quiz
        $redis.del("quiz-#{past_quiz.id}")
        
        get :till_start, params: { id: past_quiz.id, format: :json }
        
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('status')
        expect(json_response['status']).to eq('Finished')
      end
    end

    context 'knowledge quiz (ID=1) scenarios' do
      context 'when knowledge quiz is running during chat period' do
        before do
          # Ensure knowledge quiz exists with ID=1
          FactoryBot.create(:quiz, id: 1, start_time: nil)

          quiz_session = QuizSession.new(1)
          quiz_session.set_quiz_status("In progress. Wait for question.")
        end

        after do
          quiz_session = QuizSession.new(1)
          quiz_session.cleanup_quiz_data
        end

        it 'returns the in progress status' do
          get :till_start, params: { id: 1, format: :json }

          json_response = JSON.parse(response.body)
          expect(json_response).to have_key('status')
          expect(json_response['status']).to eq('In progress. Wait for question.')
        end
      end

      context 'when knowledge quiz is not running' do
        before do
          # Ensure knowledge quiz exists with ID=1
          FactoryBot.create(:quiz, id: 1, start_time: nil)
        end

        it 'returns finished status' do
          get :till_start, params: { id: 1, format: :json }

          json_response = JSON.parse(response.body)
          expect(json_response).to have_key('status')
          expect(json_response['status']).to eq('Finished')
        end
      end
    end
  end
end