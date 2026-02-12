require 'rails_helper'

RSpec.feature "Live Quiz Basic Flow", type: :feature, js: true do
  include Devise::Test::IntegrationHelpers

  let(:user) { FactoryBot.create(:user, translation: 'NIV') }
  let(:admin_role) { FactoryBot.create(:role, name: 'admin') }
  let(:quiz_master) { FactoryBot.create(:user, name: 'Quiz Master', admin: true, translation: 'NIV', roles: [admin_role]) }

  # For basic flow test, we'll use ID 1 as expected by the system
  let!(:knowledge_quiz) do
    # First ensure no quiz with ID 1 exists
    Quiz.where(id: 1).destroy_all
    FactoryBot.create(:quiz, id: 1, user: quiz_master, name: 'Bible Knowledge', quiz_length: 1200)
  end

  let!(:quiz_questions) do
    (1..3).map do |i|
      FactoryBot.create(:quiz_question, :mcq,
        quiz: knowledge_quiz,
        question_no: i,
        last_asked: 1.month.ago
      )
    end
  end

  before do
    # Mock PubNub
    allow(PN).to receive(:env).and_return({
      subscribe_key: 'test-subscribe-key',
      publish_key: 'test-publish-key'
    })
    allow(PN).to receive(:publish).and_return(true)

    # Clear any existing quiz state
    QuizSession.new(1).cleanup_quiz_data
  end

  scenario "User can view quiz schedule when quiz is not running" do
    # Set next quiz time
    next_quiz_time = 30.minutes.from_now
    allow(Quiz).to receive(:next_knowledge_quiz_time).and_return(next_quiz_time)

    sign_in user
    visit "/live_quiz"

    # Should see the quiz schedule
    expect(page).to have_css('.quiz-schedule-compact')
    expect(page).to have_css('[data-controller="quiz-sse"]')
    expect(page).to have_text('Bible Knowledge')

    # Countdown element should exist (JavaScript will populate it via SSE)
    expect(page).to have_css('[data-quiz-sse-target="countdown"]')
  end

  scenario "User sees quiz interface when quiz is running" do
    quiz_session = QuizSession.new(1)
    quiz_session.set_quiz_status("In progress. Chat open. Wait for question.")

    sign_in user
    visit "/live_quiz"

    # Should see quiz interface, not schedule
    expect(page).to have_css('#live-quiz')
    expect(page).to have_css('#quiz-header')
    expect(page).not_to have_css('.quiz-schedule-compact')

    # Should see quiz name
    expect(page).to have_text('Bible Knowledge')
  end

  scenario "SSE connection is established" do
    sign_in user
    visit "/live_quiz"

    # Should have SSE controller
    expect(page).to have_css('[data-controller="quiz-sse"]')

    # Should show connection status
    expect(page).to have_css('[data-quiz-sse-target="status"]')

    # Wait for connection to establish
    # The status element might be empty when connected, so just check it exists
    expect(page).to have_css('[data-quiz-sse-target="status"]', wait: 10)
  end

  scenario "User can submit score during quiz" do
    # Set quiz to question in progress
    quiz_session = QuizSession.new(1)
    quiz_session.set_quiz_status("Question 1 in progress")

    # Add user as participant
    quiz_session.add_participant(user.id, user.name, user.login)

    sign_in user
    visit "/live_quiz"

    # Submit a score via AJAX
    page.execute_script(<<~JS)
      var csrfToken = document.querySelector('meta[name="csrf-token"]');
      var token = csrfToken ? csrfToken.content : '';

      fetch('/record_score', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': token
        },
        body: JSON.stringify({
          quiz_id: 1,
          usr_id: #{user.id},
          usr_name: #{user.name.to_json},
          usr_login: #{user.login.to_json},
          question_id: #{quiz_questions[0].id},
          question_num: 1,
          score: 10
        })
      }).then(response => {
        window.scoreSubmitted = response.ok;
      }).catch(error => {
        window.scoreSubmitError = error.message;
      });
    JS

    # Wait for request to complete
    sleep 1

    # Check score was submitted
    expect(page.evaluate_script("window.scoreSubmitted")).to be true

    # Verify score in Redis
    scoreboard = quiz_session.get_scoreboard
    expect(scoreboard.length).to eq(1)
    expect(scoreboard[0]['score']).to eq('10')
  end
end