require 'rails_helper'

RSpec.describe "Live Quiz Name Consistency", type: :feature do
  let(:user) { FactoryBot.create(:user, name: "John Doe", login: "johndoe") }
  let(:other_user) { FactoryBot.create(:user, name: "Jane Smith", login: "janesmith") }
  let(:quiz) { FactoryBot.create(:quiz) }

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

  describe "chat configuration", js: true do
    before do
      user.update(translation: 'NIV')
      sign_in user
    end

    it "uses user name (not login) for chat messages" do
      # Visit the quiz page
      visit "/live_quiz?quiz=#{quiz.id}"

      # Wait for page to load
      expect(page).to have_css('.white-box-with-margins', wait: 5)

      # Check JavaScript variables are set correctly
      user_name = page.evaluate_script("typeof memverseUserName !== 'undefined' ? memverseUserName : null")
      user_login = page.evaluate_script("typeof memverseUserLogin !== 'undefined' ? memverseUserLogin : null")

      # If the variables are available, verify them
      if user_name && user_login
        expect(user_name).to eq("John Doe")
        expect(user_login).to eq("johndoe")

        # Verify the sendQuizChat function would use the correct name
        # by checking what value it would send
        chat_user_value = page.evaluate_script("memverseUserName")
        expect(chat_user_value).to eq("John Doe")
      else
        # If we can't access the JavaScript, at least verify the data attributes
        quiz_element = find('[data-controller="live-quiz"]', visible: false)
        expect(quiz_element['data-live-quiz-user-name-value']).to eq("John Doe")
        expect(quiz_element['data-live-quiz-user-login-value']).to eq("johndoe")
      end
    end
  end
end