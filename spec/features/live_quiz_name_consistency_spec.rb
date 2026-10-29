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

  describe "chat configuration" do
    before do
      # Temporarily enable exception details in test
      Rails.application.config.action_dispatch.show_exceptions = true

      user.update(translation: 'NIV')
      sign_in user


      # Set up the quiz session with synchronization
      setup_quiz_session_with_sync(quiz.id, "Question 1 in progress", { started_at: Time.current })

      # Create the chat channel
      setup_quiz_chat_channel(quiz.id)
    end

    after do
      Rails.application.config.action_dispatch.show_exceptions = false
      QuizSession.new(quiz.id).cleanup_quiz_data
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