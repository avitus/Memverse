require 'rails_helper'

RSpec.describe LiveQuizController, type: :controller do
  include LiveQuizHelpers

  let(:user) { FactoryBot.create(:user) }
  let(:quiz) { FactoryBot.create(:quiz, start_time: 10.minutes.from_now) }

  before do
    sign_in user
  end

  describe 'GET #quiz_state' do
    context 'when quiz has not started yet' do
      let(:quiz) { FactoryBot.create(:quiz, start_time: 10.minutes.from_now) }

      it 'returns waiting state' do
        get :quiz_state, params: { id: quiz.id, format: :json }

        json = JSON.parse(response.body)
        expect(json['state']).to eq('waiting')
        expect(json['next_transition_at']).to be_present
        expect(json['transition_to']).to eq('preparing')
        expect(json['should_refresh']).to be_falsey
        expect(json['server_time']).to be_present
      end
    end

    context 'when quiz is about to start (< 5 seconds)' do
      let(:quiz) { FactoryBot.create(:quiz, start_time: 3.seconds.from_now) }

      it 'returns preparing state' do
        get :quiz_state, params: { id: quiz.id, format: :json }

        json = JSON.parse(response.body)
        expect(json['state']).to eq('preparing')
        expect(json['transition_to']).to eq('ready')
        expect(json['should_refresh']).to be_falsey
      end
    end

    context 'when quiz is initializing' do
      before do
        setup_quiz_session_with_sync(quiz.id, 'In progress. Chat opening soon.')
      end

      it 'returns preparing state' do
        get :quiz_state, params: { id: quiz.id, format: :json }

        json = JSON.parse(response.body)
        expect(json['state']).to eq('preparing')
        expect(json['transition_to']).to eq('ready')
      end
    end

    context 'when quiz chat is open' do
      before do
        setup_quiz_session_with_sync(quiz.id, 'In progress. Chat open. Wait for question.')
      end

      it 'returns ready state without refresh when no overlay visible' do
        get :quiz_state, params: { id: quiz.id, format: :json, preparing_visible: 'false' }

        json = JSON.parse(response.body)
        expect(json['state']).to eq('ready')
        expect(json['should_refresh']).to be_falsey
        expect(json['transition_to']).to eq('running')
      end

      it 'returns ready state with refresh when preparing overlay is visible' do
        get :quiz_state, params: { id: quiz.id, format: :json, preparing_visible: 'true' }

        json = JSON.parse(response.body)
        expect(json['state']).to eq('ready')
        expect(json['should_refresh']).to be_truthy
      end
    end

    context 'when quiz is running' do
      before do
        setup_quiz_session_with_sync(quiz.id, 'In progress. Question in progress.')
      end

      it 'returns running state' do
        get :quiz_state, params: { id: quiz.id, format: :json }

        json = JSON.parse(response.body)
        expect(json['state']).to eq('running')
        expect(json['should_refresh']).to be_falsey
        expect(json['transition_to']).to eq('finished')
      end
    end

    context 'when quiz is finished' do
      before do
        setup_quiz_session_with_sync(quiz.id, 'Finished')
      end

      it 'returns finished state' do
        get :quiz_state, params: { id: quiz.id, format: :json }

        json = JSON.parse(response.body)
        expect(json['state']).to eq('finished')
        expect(json['should_refresh']).to be_falsey
        expect(json['next_transition_at']).to be_nil
      end
    end

    context 'for knowledge quiz (ID=1)' do
      before do
        # Create knowledge quiz with specific ID
        @knowledge_quiz = FactoryBot.create(:quiz, id: 1)

        # IMPORTANT: Clear any existing Redis data for this quiz
        quiz_session = QuizSession.new(1)
        quiz_session.cleanup_quiz_data

        # Mock the next knowledge quiz time
        allow(Quiz).to receive(:next_knowledge_quiz_time).and_return(15.minutes.from_now)
      end

      after do
        # Clean up Redis data after test
        quiz_session = QuizSession.new(1)
        quiz_session.cleanup_quiz_data
      end

      it 'uses scheduled times for knowledge quiz' do
        get :quiz_state, params: { id: @knowledge_quiz.id, format: :json }

        json = JSON.parse(response.body)
        expect(json['state']).to eq('waiting')
        expect(json['quiz_id']).to eq(1)
      end
    end

    context 'with preparing header' do
      before do
        request.headers['X-Quiz-Preparing'] = 'true'
        setup_quiz_session_with_sync(quiz.id, 'In progress. Chat open. Wait for question.')
      end

      it 'respects header for refresh decision' do
        get :quiz_state, params: { id: quiz.id, format: :json }

        json = JSON.parse(response.body)
        expect(json['should_refresh']).to be_truthy
      end
    end
  end
end