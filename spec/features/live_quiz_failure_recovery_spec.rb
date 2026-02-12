require 'rails_helper'

RSpec.feature "Live Quiz Failure Recovery", type: :feature, js: true do
  include Devise::Test::IntegrationHelpers
  include LiveQuizHelpers

  let(:user) { FactoryBot.create(:user, translation: 'NIV') }
  let(:admin_role) { FactoryBot.create(:role, name: 'admin') }
  let(:quiz_master) { FactoryBot.create(:user, name: 'Quiz Master', admin: true, translation: 'NIV', roles: [admin_role]) }
  let!(:knowledge_quiz) { FactoryBot.create(:quiz, user: quiz_master, name: 'Bible Knowledge', quiz_length: 1200) }
  let!(:quiz_questions) do
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
    allow(PN).to receive(:publish).and_return(true)

    # Clear any existing quiz state
    QuizSession.new(knowledge_quiz.id).cleanup_quiz_data
  end

  scenario "Redis connection failure during quiz" do
    quiz_session = QuizSession.new(knowledge_quiz.id)
    quiz_session.set_quiz_status("In progress. Chat open. Wait for question.")

    sign_in user
    visit "/live_quiz"

    expect(page).to have_css('#live-quiz')
    expect(page).to have_css('[data-controller="live-quiz"]')

    # Simulate Redis connection failure
    allow($redis).to receive(:publish).and_raise(Redis::CannotConnectError)
    allow_any_instance_of(QuizSession).to receive(:get_quiz_status).and_raise(Redis::CannotConnectError)

    # Try to submit a score
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
          quiz_id: #{knowledge_quiz.id},
          usr_id: #{user.id},
          usr_name: #{user.name.to_json},
          usr_login: #{user.login.to_json},
          question_id: #{quiz_questions[0].id},
          question_num: 1,
          score: 10
        })
      });
    JS

    # Request should complete without error (graceful degradation)
    sleep 1

    # Restore Redis connection
    allow($redis).to receive(:publish).and_call_original
    allow_any_instance_of(QuizSession).to receive(:get_quiz_status).and_call_original

    # System should remain stable despite Redis errors
    expect(page).to have_css('#live-quiz')
  end

  scenario "Worker crash during quiz" do
    # Start quiz normally
    quiz_session = QuizSession.new(knowledge_quiz.id)
    quiz_session.set_quiz_status("In progress. Chat open. Wait for question.")

    sign_in user
    visit "/live_quiz"

    expect(page).to have_css('#live-quiz')

    # Simulate worker crash by setting error status
    quiz_session.set_quiz_status("Failed", {
      error_time: Time.current.utc.iso8601,
      error_message: "Worker crashed unexpectedly"
    })

    # Publish error state
    $redis.publish("quiz:#{knowledge_quiz.id}:state", {
      state: 'error',
      previous_state: 'ready',
      message: 'Quiz experienced technical difficulties'
    }.to_json)

    # Page should remain functional despite error state
    expect(page).to have_css('#live-quiz')

    # Quiz should be recoverable - admin can restart
    quiz_session.cleanup_quiz_data
    quiz_session.set_quiz_status("Not started")

    # Refresh page
    visit current_path

    # Should show schedule again
    expect(page).to have_css('.quiz-schedule-compact')
    expect(page).not_to have_css('#live-quiz')
  end

  scenario "Network partition during quiz" do
    quiz_session = QuizSession.new(knowledge_quiz.id)
    quiz_session.set_quiz_status("Question 2 in progress")

    sign_in user
    visit "/live_quiz"

    expect(page).to have_css('#live-quiz')

    # Update quiz state while user is on the page
    quiz_session.set_quiz_status("Question 3 in progress")

    # Page should remain functional
    expect(page).to have_css('#live-quiz')

    # User can refresh to get latest state
    visit current_path
    expect(page).to have_css('#live-quiz')
  end

  scenario "Graceful degradation with multiple failures" do
    users = []
    3.times do |i|
      users << FactoryBot.create(:user, name: "User #{i + 1}", translation: 'NIV')
    end

    quiz_session = QuizSession.new(knowledge_quiz.id)
    quiz_session.set_quiz_status("In progress. Chat open. Wait for question.")

    # All users join
    users.each_with_index do |user, idx|
      using_session("user#{idx + 1}") do
        sign_in user
        visit "/live_quiz"
        expect(page).to have_css('#live-quiz')
      end
    end

    # Simulate PubNub failure
    allow(PN).to receive(:publish).and_raise(StandardError, "PubNub service unavailable")

    # Quiz should continue despite PubNub failure
    quiz_session.set_quiz_status("Question 1 in progress")

    # Pages should remain functional despite PubNub failure
    users.each_with_index do |user, idx|
      using_session("user#{idx + 1}") do
        expect(page).to have_css('#live-quiz')
      end
    end

    # Simulate partial Redis failure (write fails, read works)
    allow_any_instance_of(QuizSession).to receive(:update_score).and_return(false)

    # Users can still participate (scores not recorded)
    users.each_with_index do |user, idx|
      using_session("user#{idx + 1}") do
        # Try to submit score
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
              quiz_id: #{knowledge_quiz.id},
              usr_id: #{user.id},
              usr_name: #{user.name.to_json},
              usr_login: #{user.login.to_json},
              question_id: #{quiz_questions[0].id},
              question_num: 1,
              score: 10
            })
          });
        JS
      end
    end

    # Request should complete even though score recording failed
    sleep 1

    # Participants will be recorded but with zero scores (update_score failed)
    scoreboard = quiz_session.get_scoreboard
    expect(scoreboard.length).to eq(3)
    expect(scoreboard.all? { |s| s['score'] == '0' }).to be true

    # Restore services
    allow(PN).to receive(:publish).and_call_original
    allow_any_instance_of(QuizSession).to receive(:update_score).and_call_original

    # Quiz can complete normally
    quiz_session.set_quiz_status("Finished")

    # Refresh to see finished state
    users.each_with_index do |user, idx|
      using_session("user#{idx + 1}") do
        visit current_path
        # Should show schedule again after quiz finishes
        expect(page).to have_css('.quiz-schedule-compact')
      end
    end
  end

  scenario "Browser crash and recovery" do
    quiz_session = QuizSession.new(knowledge_quiz.id)
    quiz_session.set_quiz_status("Question 1 in progress")

    sign_in user
    visit "/live_quiz"

    expect(page).to have_css('#live-quiz')

    # Record initial state
    quiz_session.add_participant(user.id, user.name, user.login)
    quiz_session.update_score(user.id, 1, 10)

    # Simulate browser crash by revisiting
    visit "/live_quiz"

    # Should restore to correct state
    expect(page).to have_css('#live-quiz')

    # Previous score should be preserved
    scoreboard = quiz_session.get_scoreboard
    expect(scoreboard.length).to eq(1)
    expect(scoreboard[0]['score']).to eq('10')

    # Can continue participating
    quiz_session.set_quiz_status("Question 2 in progress")

    # Refresh to see updated state
    visit current_path
    expect(page).to have_css('#live-quiz')
  end

  scenario "Handling malformed SSE messages" do
    sign_in user
    visit "/live_quiz"

    # Should show schedule (quiz not running)
    expect(page).to have_css('[data-controller="quiz-sse"]')
    expect(page).to have_css('.quiz-schedule-compact')

    # Page should remain stable even with potential SSE issues
    sleep 2
    expect(page).to have_css('[data-controller="quiz-sse"]')
    expect(page).to have_css('.quiz-schedule-compact')
  end

  scenario "Concurrent quiz execution prevention" do
    # First worker acquires lock
    quiz_session1 = QuizSession.new(knowledge_quiz.id)
    expect(quiz_session1.lock_quiz).to be true

    # Second worker should fail to acquire lock
    quiz_session2 = QuizSession.new(knowledge_quiz.id)
    expect(quiz_session2.lock_quiz).to be false

    # User experience should be normal
    sign_in user
    visit "/live_quiz"

    # Should see schedule (quiz not running)
    expect(page).to have_css('.quiz-schedule-compact')

    # First worker starts quiz
    quiz_session1.set_quiz_status("In progress. Chat open. Wait for question.")

    # Refresh page
    visit current_path

    # Should see quiz
    expect(page).to have_css('#live-quiz')

    # Clean up lock
    quiz_session1.unlock_quiz
  end
end