require 'rails_helper'
require_relative '../support/live_quiz_helpers'

RSpec.describe "Live Quiz Name Consistency", type: :feature, js: true do
  # Force truncation strategy for all tests in this describe block
  before(:all) do
    DatabaseCleaner[:active_record].strategy = :truncation, {except: %w[final_verses]}
  end
  let(:user) { FactoryBot.create(:user, name: "John Doe", login: "johndoe") }
  let(:other_user) { FactoryBot.create(:user, name: "Jane Smith", login: "janesmith") }
  let(:quiz) { FactoryBot.create(:live_ready_quiz) }

  describe "scoreboard displays correct names" do
    it "shows user names (not logins) in the scoreboard" do
      # Initialize quiz session
      quiz_session = QuizSession.new(quiz.id)

      # Debug: Check user info
      puts "User ID: #{user.id}, name_or_login: #{user.name_or_login} (name: #{user.name}, login: #{user.login})"
      puts "Other user ID: #{other_user.id}, name_or_login: #{other_user.name_or_login} (name: #{other_user.name}, login: #{other_user.login})"

      # Add participants with their names and logins
      quiz_session.add_participant(user.id, user.name_or_login, user.login)
      quiz_session.add_participant(other_user.id, other_user.name_or_login, other_user.login)

      # Update scores
      quiz_session.update_score(user.id, 1, 10)
      quiz_session.update_score(other_user.id, 1, 8)

      # Get scoreboard
      scoreboard = quiz_session.get_scoreboard

      # Scoreboard is sorted by score, so find users by their IDs
      john_score = scoreboard.find { |s| s['id'] == user.id.to_s }
      jane_score = scoreboard.find { |s| s['id'] == other_user.id.to_s }

      # Verify we found both users
      expect(john_score).not_to be_nil
      expect(jane_score).not_to be_nil

      # Verify scoreboard uses names, not logins
      expect(john_score['name']).to eq("John Doe")
      expect(jane_score['name']).to eq("Jane Smith")

      # Verify logins are stored separately
      expect(john_score['login']).to eq("johndoe")
      expect(jane_score['login']).to eq("janesmith")
    end
  end

  describe "chat configuration" do
    before do
      # Temporarily enable exception details in test
      Rails.application.config.action_dispatch.show_exceptions = true

      user.update(translation: 'NIV')
      sign_in user

      # Debug quiz setup
      puts "\nQuiz ID: #{quiz.id}"
      puts "Quiz Length: #{quiz.quiz_length}"
      puts "Quiz Open?: #{quiz.open?}"
      puts "Quiz User: #{quiz.user.inspect}"

      # Set up the quiz session with synchronization
      setup_quiz_session_with_sync(quiz.id, "in_progress", { started_at: Time.current })

      # Create the chat channel
      setup_quiz_chat_channel(quiz.id)
    end

    after do
      # Reset to default
      Rails.application.config.action_dispatch.show_exceptions = false
    end

    it "uses user name (not login) for chat messages" do
      # Visit the live quiz page and wait for it to load
      visit_live_quiz_and_wait(quiz)

      # Verify the quiz interface is showing (not the schedule)
      expect(quiz_interface_visible?).to be true

      # Wait for JavaScript to initialize
      sleep 0.5

      # Verify JavaScript variables for modern view
      verify_modern_chat_config(
        expected_name: "John Doe",
        expected_login: "johndoe"
      )
    end
  end
end