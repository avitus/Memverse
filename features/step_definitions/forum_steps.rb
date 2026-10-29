# Forum-specific step definitions

# Alternative step to avoid ambiguity with generic web_steps
When /^I navigate to the forum home page$/ do
  visit '/forum'
end

# Thredded only lets users with at least two completed sessions (or admins) post.
# See User#thredded_can_write_messageboards.
Given(/^I have completed enough memorization sessions to post on the forum$/) do
  user = @user || @current_user
  raise "No user account has been created yet" unless user

  2.times { |i| FactoryBot.create(:progress_report, user_id: user.id, entry_date: Date.today - 1 - i) } # skipcq: RB-RL1014 (ProgressReport dates use Date.today)
  expect(user.reload.thredded_can_write_messageboards).to include(@feedback_board)
end

Then /^the feedback board should contain the topic "([^"]*)"$/ do |title|
  topic = Thredded::Topic.find_by(title: title)
  expect(topic).not_to be_nil, "Expected a topic titled #{title.inspect} to have been created"
  expect(topic.messageboard).to eq(@feedback_board)
  expect(topic.user).to eq(@user || @current_user)
end
