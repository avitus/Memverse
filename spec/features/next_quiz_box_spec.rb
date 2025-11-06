require 'rails_helper'

RSpec.feature "Next Quiz Box", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { FactoryBot.create(:user, translation: 'NIV') }
  let(:quiz_master) { FactoryBot.create(:user, name: 'Quiz Master', translation: 'NIV') }
  let!(:quiz) { Quiz.find_or_create_by(id: 1) { |q| q.name = "Knowledge Quiz"; q.user = quiz_master } }

  before do
    # Clear any stale quiz data from Redis
    quiz_session = QuizSession.new(quiz.id)
    quiz_session.cleanup_quiz_data
    $redis.del("chat-quiz-#{quiz.id}")

    # Set up chat channel mock
    allow(ChatChannel).to receive(:find).and_return(
      double('ChatChannel', channel: "quiz-#{quiz.id}", status: 'open')
    )

    # Sign in as user
    sign_in user
  end

  describe "when visiting /live_quiz with no quiz running" do
    context "when next quiz is scheduled" do
      before do
        # Mock the next quiz time to be 2 hours from now
        next_quiz_time = 2.hours.from_now
        allow(Quiz).to receive(:next_knowledge_quiz_time).and_return(next_quiz_time)
        allow(Quiz).to receive(:knowledge_quiz_schedule).and_return(["Tuesday 5:00 PM UTC", "Saturday 11:00 PM UTC"])
      end

      it "displays the Next Quiz box with upcoming quiz time" do
        get "/live_quiz", params: { legacy: 'false' }

        expect(response).to have_http_status(:ok)

        # Check that we're on the quiz page but not in a running quiz
        expect(response.body).to include('white-box-bg quiz-schedule-compact')

        # Verify the Next Quiz card is present
        expect(response.body).to include('next-quiz-card')
        expect(response.body).to include('Next Quiz')

        # Verify the badge shows "Upcoming" for quiz more than 1 hour away
        expect(response.body).to include('quiz-badge-upcoming')
        expect(response.body).to include('Upcoming')

        # Verify the time display elements are present
        expect(response.body).to include('next-quiz-time')
        expect(response.body).to include('quiz-day')
        expect(response.body).to include('data-utc-datetime')
        expect(response.body).to include('quiz-local-time')

        # Verify the countdown timer element is present
        expect(response.body).to include('quiz-countdown')
        expect(response.body).to include('data-target-time')

        # The quiz should NOT be showing as running
        expect(response.body).not_to include('quiz-container')
        expect(response.body).not_to include('quiz-chat')
      end
    end

    context "when next quiz is starting soon (less than 1 hour)" do
      before do
        # Mock the next quiz time to be 30 minutes from now
        next_quiz_time = 30.minutes.from_now
        allow(Quiz).to receive(:next_knowledge_quiz_time).and_return(next_quiz_time)
      end

      it "displays the Next Quiz box with 'Starting Soon' badge" do
        get "/live_quiz", params: { legacy: 'false' }

        expect(response).to have_http_status(:ok)

        # Verify the Next Quiz card is present
        expect(response.body).to include('next-quiz-card')
        expect(response.body).to include('Next Quiz')

        # Verify the badge shows "Starting Soon" for quiz less than 1 hour away
        expect(response.body).to include('quiz-badge-urgent')
        expect(response.body).to include('Starting Soon')
      end
    end

    context "when no next quiz is scheduled" do
      before do
        allow(Quiz).to receive(:next_knowledge_quiz_time).and_return(nil)
      end

      it "does not display the Next Quiz box" do
        get "/live_quiz", params: { legacy: 'false' }

        expect(response).to have_http_status(:ok)

        # Verify the Next Quiz card is NOT present
        expect(response.body).not_to include('next-quiz-card')

        # The schedule and details cards should still be present
        expect(response.body).to include('schedule-card')
        expect(response.body).to include('details-card')

        # Verify the specific Next Quiz heading is not present in the card structure
        expect(response.body).not_to match(/<h3>Next Quiz<\/h3>/)
      end
    end
  end

  describe "when a quiz is in chat period" do
    before do
      # Set up quiz in chat period
      quiz_session = QuizSession.new(quiz.id)
      quiz_session.set_quiz_status("In progress. Chat open. Wait for question.")

      # Set next quiz time
      allow(Quiz).to receive(:next_knowledge_quiz_time).and_return(2.hours.from_now)
    end

    after do
      # Clean up
      quiz_session = QuizSession.new(quiz.id)
      quiz_session.cleanup_quiz_data
    end

    it "does not display the Next Quiz box during chat period" do
      get "/live_quiz", params: { legacy: 'false' }

      expect(response).to have_http_status(:ok)

      # During chat period, the Next Quiz box should NOT be shown
      # because the quiz has already started
      expect(response.body).not_to include('next-quiz-card')

      # The quiz interface should be shown instead
      expect(response.body).to include('quiz-container')
    end
  end

  describe "when quiz questions are running" do
    before do
      # Set up quiz with questions actively running
      quiz_session = QuizSession.new(quiz.id)
      quiz_session.set_quiz_status("Question 1 in progress")

      # Set next quiz time
      allow(Quiz).to receive(:next_knowledge_quiz_time).and_return(2.hours.from_now)
    end

    after do
      # Clean up
      quiz_session = QuizSession.new(quiz.id)
      quiz_session.cleanup_quiz_data
    end

    it "does not display the Next Quiz box" do
      get "/live_quiz", params: { legacy: 'false' }

      expect(response).to have_http_status(:ok)

      # When questions are running, the Next Quiz box should NOT be shown
      expect(response.body).not_to include('next-quiz-card')
    end
  end

  describe "JavaScript time conversion" do
    before do
      # Set a specific next quiz time
      next_quiz_time = Time.parse("2025-01-15 18:00:00 UTC")
      allow(Quiz).to receive(:next_knowledge_quiz_time).and_return(next_quiz_time)
    end

    it "includes the UTC datetime in data attributes for JavaScript to convert" do
      get "/live_quiz", params: { legacy: 'false' }

      expect(response).to have_http_status(:ok)

      # Verify the Next Quiz elements have data attributes with ISO8601 time
      expected_time = "2025-01-15T18:00:00Z"

      # Check that the elements with data attributes are present
      expect(response.body).to include('class="quiz-day" data-utc-datetime="' + expected_time + '"')
      expect(response.body).to include('class="quiz-local-time" data-utc-datetime="' + expected_time + '"')
      expect(response.body).to include('id="quiz-countdown" data-target-time="' + expected_time + '"')

      # Note: The actual time display is populated by JavaScript
      # In a full JS test, we would verify the converted local time appears
    end
  end
end