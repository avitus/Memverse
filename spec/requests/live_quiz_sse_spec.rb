require 'rails_helper'

RSpec.describe "Live Quiz SSE", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { FactoryBot.create(:user, translation: 'NIV') }
  let(:admin_role) { FactoryBot.create(:role, name: 'admin') }
  let(:quiz_master) { FactoryBot.create(:user, name: 'Quiz Master', admin: true, translation: 'NIV', roles: [admin_role]) }
  let!(:knowledge_quiz) { FactoryBot.create(:quiz, id: 1, user: quiz_master, name: 'Bible Knowledge') }

  describe "GET /live_quiz/events" do
    before do
      sign_in user
      # Clear any existing connections
      SseConnectionManager.instance.instance_variable_set(:@connections, {})
    end

    after do
      # Clean up after each test
      SseConnectionManager.instance.instance_variable_set(:@connections, {})
    end

    it "returns SSE headers" do
      # We need to stop the SSE loop quickly to test headers
      allow_any_instance_of(LiveQuizController).to receive(:sleep).and_raise(ActionController::Live::ClientDisconnected)

      get "/live_quiz/events?id=1"

      expect(response.headers['Content-Type']).to eq('text/event-stream')
      expect(response.headers['Cache-Control']).to eq('no-cache')
      expect(response.headers['X-Accel-Buffering']).to eq('no')
      expect(response.headers['Connection']).to eq('keep-alive')
    end

    it "sends initial quiz state" do
      quiz_session = QuizSession.new(1)
      quiz_session.set_quiz_status("Not started")

      # Capture the output
      output = StringIO.new
      allow_any_instance_of(ActionDispatch::Response::Buffer).to receive(:write) do |_, data|
        output.write(data)
      end
      allow_any_instance_of(LiveQuizController).to receive(:sleep).and_raise(ActionController::Live::ClientDisconnected)

      get "/live_quiz/events?id=1"

      expect(output.string).to include("event: quiz-state")
      expect(output.string).to include('"state":"waiting"')
    end

    context "when quiz is preparing" do
      before do
        quiz_session = QuizSession.new(1)
        quiz_session.set_quiz_status("In progress. Initializing...")
      end

      it "returns preparing state" do
        output = StringIO.new
        allow_any_instance_of(ActionDispatch::Response::Buffer).to receive(:write) do |_, data|
          output.write(data)
        end
        allow_any_instance_of(LiveQuizController).to receive(:sleep).and_raise(ActionController::Live::ClientDisconnected)

        get "/live_quiz/events?id=1"

        expect(output.string).to include("event: quiz-state")
        expect(output.string).to include('"state":"preparing"')
      end
    end

    context "when quiz is ready" do
      before do
        quiz_session = QuizSession.new(1)
        quiz_session.set_quiz_status("In progress. Chat open. Wait for question.")
      end

      it "returns ready state" do
        output = StringIO.new
        allow_any_instance_of(ActionDispatch::Response::Buffer).to receive(:write) do |_, data|
          output.write(data)
        end
        allow_any_instance_of(LiveQuizController).to receive(:sleep).and_raise(ActionController::Live::ClientDisconnected)

        get "/live_quiz/events?id=1"

        expect(output.string).to include("event: quiz-state")
        expect(output.string).to include('"state":"ready"')
      end
    end

    context "with connection management" do
      it "registers connection with manager" do
        allow_any_instance_of(LiveQuizController).to receive(:sleep).and_raise(ActionController::Live::ClientDisconnected)
        connection_manager = SseConnectionManager.instance

        expect(connection_manager).to receive(:register_connection).with(user.id, 1, anything).and_call_original

        get "/live_quiz/events?id=1"
      end

      it "unregisters connection on disconnect" do
        allow_any_instance_of(LiveQuizController).to receive(:sleep).and_raise(ActionController::Live::ClientDisconnected)
        connection_manager = SseConnectionManager.instance

        allow(connection_manager).to receive(:register_connection).and_call_original
        expect(connection_manager).to receive(:unregister_connection).with(anything).and_call_original

        get "/live_quiz/events?id=1"
      end
    end

    context "with rate limiting" do
      it "rejects connections when limit exceeded" do
        # Mock the connection manager to simulate rate limit
        connection_manager = SseConnectionManager.instance
        allow(connection_manager).to receive(:register_connection).and_raise(SseConnectionManager::ConnectionLimitExceeded, "Rate limit exceeded")

        output = StringIO.new
        allow_any_instance_of(ActionDispatch::Response::Buffer).to receive(:write) do |_, data|
          output.write(data)
        end

        get "/live_quiz/events?id=1"

        expect(output.string).to include("event: error")
        expect(output.string).to include("RATE_LIMIT")
      end
    end

    context "without authentication" do
      before do
        sign_out user
      end

      it "does not require authentication for SSE endpoint" do
        allow_any_instance_of(LiveQuizController).to receive(:sleep).and_raise(ActionController::Live::ClientDisconnected)

        get "/live_quiz/events?id=1"

        # SSE endpoints should be accessible without authentication
        expect(response.headers['Content-Type']).to eq('text/event-stream')
      end
    end

    context "error handling" do
      it "handles client disconnect gracefully" do
        allow_any_instance_of(LiveQuizController).to receive(:sleep).and_raise(ActionController::Live::ClientDisconnected)
        allow(Rails.logger).to receive(:info).and_call_original

        expect { get "/live_quiz/events?id=1" }.not_to raise_error
        expect(Rails.logger).to have_received(:info).with(/SSE client disconnected/)
      end

      it "closes stream on any error" do
        allow_any_instance_of(LiveQuizController).to receive(:sleep).and_raise(StandardError, "Test error")
        allow(Rails.logger).to receive(:error).and_call_original

        expect { get "/live_quiz/events?id=1" }.not_to raise_error
        expect(Rails.logger).to have_received(:error).with(/SSE error.*Test error/)
      end

      it "cleans up resources in ensure block" do
        allow_any_instance_of(LiveQuizController).to receive(:sleep).and_raise(StandardError, "Test error")
        connection_manager = SseConnectionManager.instance

        allow(connection_manager).to receive(:register_connection).and_call_original
        expect(connection_manager).to receive(:unregister_connection).with(anything).and_call_original

        get "/live_quiz/events?id=1"
      end
    end
  end
end