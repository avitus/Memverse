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
          allow(quiz_session).to receive(:get_quiz_status).and_return(nil)
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
          allow(quiz_session).to receive(:get_quiz_status).and_return("In progress. Wait for question.")
        end

        it 'does not calculate next quiz time' do
          get :live_quiz, params: { quiz: quiz.id }

          expect(assigns(:quiz_running)).to eq(true)
          expect(assigns(:next_quiz_time)).to be_nil
        end

        it 'sets quiz_preparing to false when quiz is waiting for question' do
          get :live_quiz, params: { quiz: quiz.id }

          expect(assigns(:quiz_running)).to eq(true)
          expect(assigns(:quiz_preparing)).to eq(false)
        end
      end

      context 'when quiz is in preparing state' do
        before do
          allow(quiz_session).to receive(:quiz_in_progress?).and_return(true)
          allow(quiz_session).to receive(:get_quiz_status).and_return("In progress. Initializing...")
        end

        it 'sets quiz_preparing to true' do
          get :live_quiz, params: { quiz: quiz.id }

          # With unified state machine, "preparing" state means not running yet
          expect(assigns(:quiz_running)).to eq(false)
          expect(assigns(:quiz_preparing)).to eq(true)
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
    let(:quiz_session) { QuizSession.new(quiz.id) }
    let(:mcq) { FactoryBot.create(:quiz_question, :mcq) }

    before do
      quiz_session.cleanup_quiz_data
      quiz_session.open_question(1, mcq.id, 30)
    end

    after { quiz_session.cleanup_quiz_data }

    def scoreboard_score(user_id)
      quiz_session.get_scoreboard.find { |entry| entry['id'] == user_id.to_s }&.fetch('score').to_i
    end

    context 'when signed out' do
      it 'rejects the request and records nothing' do
        post :record_score, params: { quiz_id: quiz.id, question_num: 1, answer: 'B', usr_id: user.id }, format: :json

        expect(response).to have_http_status(:unauthorized)
        expect(quiz_session.get_scoreboard).to be_empty
      end
    end

    context 'when signed in' do
      before { sign_in user }

      it 'grades the answer on the server and returns the score' do
        post :record_score, params: { quiz_id: quiz.id, question_num: 1, answer: 'B' }, format: :json

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq('status' => 'graded', 'score' => 10)
        expect(scoreboard_score(user.id)).to eq(10)
      end

      it 'does not reveal the correct answer in the response' do
        post :record_score, params: { quiz_id: quiz.id, question_num: 1, answer: 'A' }, format: :json

        expect(JSON.parse(response.body)).to eq('status' => 'graded', 'score' => 0)
      end

      it 'ignores a score sent by the browser' do
        post :record_score, params: { quiz_id: quiz.id, question_num: 1, answer: 'A', score: '10' }, format: :json

        expect(scoreboard_score(user.id)).to eq(0)
      end

      it 'ignores a user id sent by the browser' do
        victim = FactoryBot.create(:user)

        post :record_score, params: {
          quiz_id: quiz.id, question_num: 1, answer: 'B',
          usr_id: victim.id, usr_name: 'Spoofed', usr_login: 'spoofed'
        }, format: :json

        expect(scoreboard_score(victim.id)).to eq(0)
        expect(scoreboard_score(user.id)).to eq(10)
        expect(quiz_session.get_scoreboard.map { |entry| entry['name'] }).not_to include('Spoofed')
      end

      it 'reports a second answer to the same question as a duplicate' do
        post :record_score, params: { quiz_id: quiz.id, question_num: 1, answer: 'A' }, format: :json
        post :record_score, params: { quiz_id: quiz.id, question_num: 1, answer: 'B' }, format: :json

        expect(JSON.parse(response.body)).to eq('status' => 'duplicate', 'score' => nil)
        expect(scoreboard_score(user.id)).to eq(0)
      end

      it 'reports an answer to a closed question' do
        post :record_score, params: { quiz_id: quiz.id, question_num: 2, answer: 'B' }, format: :json

        expect(JSON.parse(response.body)).to eq('status' => 'closed', 'score' => nil)
      end

      it 'lists a user who let the question time out' do
        post :record_score, params: { quiz_id: quiz.id, question_num: 1 }, format: :json

        expect(JSON.parse(response.body)).to eq('status' => 'unanswered', 'score' => nil)
        expect(quiz_session.get_scoreboard.map { |entry| entry['id'] }).to include(user.id.to_s)
      end
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

      context 'during chat period' do
        let(:chat_quiz) { FactoryBot.create(:quiz, start_time: 5.minutes.ago) }

        before do
          quiz_session = QuizSession.new(chat_quiz.id)
          chat_start_time = 2.minutes.ago.utc
          chat_duration = 300 # 5 minutes

          quiz_session.set_quiz_status("In progress. Chat open. Wait for question.", {
            chat_start_time: chat_start_time.iso8601,
            chat_duration: chat_duration
          })
        end

        after do
          quiz_session = QuizSession.new(chat_quiz.id)
          quiz_session.cleanup_quiz_data
        end

        it 'returns countdown information for non-knowledge quizzes' do
          get :till_start, params: { id: chat_quiz.id, format: :json }

          json_response = JSON.parse(response.body)
          expect(json_response).to have_key('status')
          expect(json_response['status']).to eq('In progress. Chat open. Wait for question.')
          expect(json_response).to have_key('chat_countdown')
          expect(json_response['chat_countdown']).to eq(true)
          expect(json_response).to have_key('countdown_seconds')
          expect(json_response['countdown_seconds']).to be_between(1, 180).inclusive # About 3 minutes left
        end
      end
    end
    
    context 'when quiz is finished' do
      let(:past_quiz) { FactoryBot.create(:quiz, start_time: 2.hours.ago) }
      
      it 'returns finished status' do
        # Ensure no Redis state exists for this quiz. Quiz ids are reused across examples after the
        # database is cleaned, while Redis is not, so a status key left by an earlier example would
        # make till_start report that quiz as still running. cleanup_quiz_data removes every key.
        QuizSession.new(past_quiz.id).cleanup_quiz_data
        
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
          quiz_session.set_quiz_status("In progress. Chat open. Wait for question.")
        end

        after do
          quiz_session = QuizSession.new(1)
          quiz_session.cleanup_quiz_data
        end

        it 'returns the in progress status' do
          get :till_start, params: { id: 1, format: :json }

          json_response = JSON.parse(response.body)
          expect(json_response).to have_key('status')
          expect(json_response['status']).to eq('In progress. Chat open. Wait for question.')
        end
      end

      context 'when quiz is in chat period with countdown' do
        before do
          # Ensure knowledge quiz exists with ID=1
          FactoryBot.create(:quiz, id: 1, start_time: nil)

          quiz_session = QuizSession.new(1)
          chat_start_time = Time.current.utc
          chat_duration = 300 # 5 minutes

          quiz_session.set_quiz_status("In progress. Chat open. Wait for question.", {
            chat_start_time: chat_start_time.iso8601,
            chat_duration: chat_duration
          })
        end

        after do
          quiz_session = QuizSession.new(1)
          quiz_session.cleanup_quiz_data
        end

        it 'returns countdown information during chat period' do
          get :till_start, params: { id: 1, format: :json }

          json_response = JSON.parse(response.body)
          expect(json_response).to have_key('status')
          expect(json_response['status']).to eq('In progress. Chat open. Wait for question.')
          expect(json_response).to have_key('chat_countdown')
          expect(json_response['chat_countdown']).to eq(true)
          expect(json_response).to have_key('countdown_seconds')
          expect(json_response['countdown_seconds']).to be_between(1, 300).inclusive
        end
      end

      context 'when chat period has expired' do
        before do
          # Ensure knowledge quiz exists with ID=1
          FactoryBot.create(:quiz, id: 1, start_time: nil)

          quiz_session = QuizSession.new(1)
          chat_start_time = 10.minutes.ago.utc # Started 10 minutes ago
          chat_duration = 300 # 5 minutes duration

          quiz_session.set_quiz_status("In progress. Chat open. Wait for question.", {
            chat_start_time: chat_start_time.iso8601,
            chat_duration: chat_duration
          })
        end

        after do
          quiz_session = QuizSession.new(1)
          quiz_session.cleanup_quiz_data
        end

        it 'returns status without countdown when chat period is over' do
          get :till_start, params: { id: 1, format: :json }

          json_response = JSON.parse(response.body)
          expect(json_response).to have_key('status')
          expect(json_response['status']).to eq('In progress. Chat open. Wait for question.')
          expect(json_response).not_to have_key('chat_countdown')
          expect(json_response).not_to have_key('countdown_seconds')
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