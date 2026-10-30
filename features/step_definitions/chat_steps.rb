# Chat-related step definitions

CHAT_TEST_CHANNEL = 'chat-7'.freeze

# Chat state lives in Redis, outside the database transaction, so clean it up explicitly.
After do
  $redis.del("chat-#{CHAT_TEST_CHANNEL}")
  banned_keys = $redis.keys("banned-*")
  $redis.del(*banned_keys) if banned_keys.any?
end

def chat_user(username)
  email = { 'testuser' => 'testuser@test.com', 'admin' => 'admin@test.com' }.fetch(username) do
    raise "Unknown chat user #{username.inspect}"
  end
  user = User.find_by(email: email)
  expect(user).not_to be_nil, "User #{username} not found"
  user
end

def chat_json_response
  expect(page.driver.response.headers['Content-Type']).to include('application/json')
  JSON.parse(page.driver.response.body)
end

Given(/^I am signed in as "([^"]*)"$/) do |username|
  if username == 'testuser'
    step %{I sign in as "testuser@test.com/password"}
  elsif username == 'admin'
    step %{I sign in as "admin@test.com/adminpass"}
  end
end

Given(/^I am not signed in$/) do
  visit '/users/sign_out'
end

Given(/^user "([^"]*)" exists$/) do |username|
  chat_user(username)
end

Given(/^user "([^"]*)" is banned from chat$/) do |username|
  $redis.set("banned-#{chat_user(username).id}", "banned")
end

Given(/^user "([^"]*)" is not banned from chat$/) do |username|
  $redis.del("banned-#{chat_user(username).id}")
end

Given(/^the admin has quiz management permissions$/) do
  admin = User.find_by(admin: true)
  expect(admin).not_to be_nil, "Admin user not found"
  
  # Create admin role if it doesn't exist and assign it to the admin user
  admin_role = Role.find_or_create_by(name: 'admin')
  unless admin.roles.include?(admin_role)
    admin.roles << admin_role
    admin.save!
  end
  
  # Verify the admin can manage Quiz
  ability = Ability.new(admin)
  expect(ability.can?(:manage, Quiz)).to be true
end

When(/^I toggle the chat channel status$/) do
  @channel_status_before = ChatChannel.find(CHAT_TEST_CHANNEL).status
  page.driver.header 'X-Requested-With', 'XMLHttpRequest'
  page.driver.post('/chat/toggle_channel', { channel: CHAT_TEST_CHANNEL })
end

When(/^I (?:try to )?(?:ban|unban) user "([^"]*)" from chat$/) do |username|
  page.driver.header 'X-Requested-With', 'XMLHttpRequest'
  page.driver.get("/chat/toggle_ban?user_id=#{chat_user(username).id}")
end

Then(/^I should see a message input field$/) do
  expect(page).to have_selector('input#message-to-send')
end

Then(/^I should see a "([^"]*)" button$/) do |button_text|
  expect(page).to have_button(button_text)
end

Then(/^the channel status should change$/) do
  status_after = ChatChannel.find(CHAT_TEST_CHANNEL).status
  expect(%w[Open Closed]).to include(status_after)
  expect(status_after).not_to eq(@channel_status_before)
end

Then(/^I should receive a JSON response with the new status$/) do
  expect(chat_json_response['status']).to eq(ChatChannel.find(CHAT_TEST_CHANNEL).status)
end

Then(/^user "([^"]*)" should be banned from chat$/) do |username|
  expect($redis.exists("banned-#{chat_user(username).id}")).to eq(1)
end

Then(/^I should receive a JSON response confirming the ban$/) do
  expect(chat_json_response['status']).to eq('Banned')
end

Then(/^user "([^"]*)" should not be banned from chat$/) do |username|
  expect($redis.exists("banned-#{chat_user(username).id}")).to eq(0)
end

Then(/^I should receive a JSON response confirming the unban$/) do
  expect(chat_json_response['status']).to eq('Ban revoked')
end

Then(/^I should receive a JSON response with no status change$/) do
  expect(chat_json_response['status']).to be_nil
end

Then(/^I should be redirected to the sign in page$/) do
  expect(current_path).to eq('/users/sign_in')
end

Then(/^the page should contain my user ID in JavaScript variables$/) do
  expect(page.html).to include("const userId = \"#{chat_user('testuser').id}\"")
end

Then(/^the page should contain my username in JavaScript variables$/) do
  expect(page.html).to include("const userName = \"#{chat_user('testuser').name_or_login}\"")
end

Then(/^the page should contain my avatar URL in JavaScript variables$/) do
  expect(page.html).to include("const userAvatar = \"#{chat_user('testuser').blog_avatar_url}\"")
end
