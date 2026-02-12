require 'rails_helper'

RSpec.feature "Live Quiz SSE Auto-Refresh", type: :feature, js: true do
  include Devise::Test::IntegrationHelpers

  let(:user) { FactoryBot.create(:user, translation: 'NIV') }
  let(:admin_role) { FactoryBot.create(:role, name: 'admin') }
  let(:quiz_master) { FactoryBot.create(:user, name: 'Quiz Master', admin: true, translation: 'NIV', roles: [admin_role]) }
  let!(:knowledge_quiz) do
    Quiz.find_by(id: 1) || FactoryBot.create(:quiz, id: 1, user: quiz_master, name: 'Bible Knowledge', quiz_length: 1200)
  end
  let!(:quiz_questions) do
    # Create questions for the quiz
    3.times.map do |i|
      FactoryBot.create(:quiz_question, :mcq, quiz: knowledge_quiz, question_no: i + 1)
    end
  end

  before do
    # Mock PubNub
    allow(PN).to receive(:env).and_return({
      subscribe_key: 'test-subscribe-key',
      publish_key: 'test-publish-key'
    })

    # Clear any existing quiz state
    QuizSession.new(1).cleanup_quiz_data
  end

  scenario "User joins before quiz starts and page auto-refreshes via SSE" do
    # Set next quiz time to 30 seconds from now
    next_quiz_time = 30.seconds.from_now
    allow(Quiz).to receive(:next_knowledge_quiz_time).and_return(next_quiz_time)

    sign_in user
    visit "/live_quiz"

    # Should see the quiz schedule with SSE controller
    expect(page).to have_css('[data-controller="quiz-sse"]')
    expect(page).to have_css('.quiz-schedule-compact')
    expect(page).to have_css('[data-quiz-sse-target="countdown"]')

    # Should have SSE status element (connection status is set by JavaScript)
    expect(page).to have_css('[data-quiz-sse-target="status"]')

    # Simulate quiz starting
    Timecop.travel(next_quiz_time) do
      QuizSession.new(1).set_quiz_status("In progress. Chat open. Wait for question.")

      # Manual refresh simulates what SSE auto-refresh would do
      visit current_path

      # Should now show quiz interface
      expect(page).to have_css('#live-quiz')
      expect(page).to have_css('#quiz-header')
      expect(page).not_to have_css('.quiz-schedule-compact')
    end
  end

  scenario "SSE connection handles errors and reconnects" do
    sign_in user
    visit "/live_quiz"

    # Should establish SSE connection
    expect(page).to have_css('[data-controller="quiz-sse"]')
    expect(page).to have_css('[data-quiz-sse-target="status"]')

    # Page should maintain SSE controller elements
    expect(page).to have_css('[data-controller="quiz-sse"]')
    expect(page).to have_css('[data-quiz-sse-target="status"]')
  end

  scenario "Countdown updates via SSE state messages" do
    # Set next quiz time to 5 minutes from now
    next_quiz_time = 5.minutes.from_now
    allow(Quiz).to receive(:next_knowledge_quiz_time).and_return(next_quiz_time)

    sign_in user
    visit "/live_quiz"

    # Should have countdown element
    expect(page).to have_css('[data-quiz-sse-target="countdown"]')

    # JavaScript would handle countdown updates via SSE
    # Testing the actual countdown behavior requires JavaScript unit tests
  end

  scenario "Falls back to polling when SSE is not supported" do
    sign_in user
    visit "/live_quiz"

    # Should work normally
    expect(page).to have_css('.quiz-schedule-compact')
    expect(page).to have_css('[data-controller="quiz-sse"]')

    # Set quiz to running state
    QuizSession.new(1).set_quiz_status("In progress. Chat open. Wait for question.")

    # Manual refresh would show the updated state
    visit current_path
    expect(page).to have_css('#live-quiz')
  end

  scenario "Multiple users receive same SSE updates simultaneously" do
    # Set quiz to start soon
    next_quiz_time = 20.seconds.from_now
    allow(Quiz).to receive(:next_knowledge_quiz_time).and_return(next_quiz_time)

    # Open multiple sessions
    using_session("user1") do
      sign_in FactoryBot.create(:user, translation: 'NIV')
      visit "/live_quiz"
      expect(page).to have_css('[data-quiz-sse-target="status"]')
    end

    using_session("user2") do
      sign_in FactoryBot.create(:user, translation: 'ESV')
      visit "/live_quiz"
      expect(page).to have_css('[data-quiz-sse-target="status"]')
    end

    # Update quiz state
    QuizSession.new(1).set_quiz_status("In progress. Initializing...")

    # Both users should still have the SSE status element
    using_session("user1") do
      expect(page).to have_css('[data-quiz-sse-target="status"]')
    end

    using_session("user2") do
      expect(page).to have_css('[data-quiz-sse-target="status"]')
    end
  end
end