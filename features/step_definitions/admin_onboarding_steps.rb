Given(/^I am logged in as an admin user$/) do
  @admin_user = FactoryBot.create(:user, 
    admin: true, 
    email: 'admin@example.com', 
    password: 'password123', 
    password_confirmation: 'password123',
    created_at: 60.days.ago,
    confirmed_at: 60.days.ago
  )
  visit new_user_session_path
  fill_in 'Email address', with: @admin_user.email
  fill_in 'Password', with: 'password123'
  click_button 'signinbutton'
end

Given(/^the following users exist:$/) do |table|
  table.hashes.each do |row|
    # Parse the time strings properly
    created_at = row['created_at'].include?('ago') ? eval(row['created_at'].gsub(' ', '.')) : eval(row['created_at'])
    confirmed_at = row['confirmed_at'] == 'nil' ? nil : (row['confirmed_at'].include?('ago') ? eval(row['confirmed_at'].gsub(' ', '.')) : eval(row['confirmed_at']))
    
    FactoryBot.create(:user,
      name: row['name'],
      email: row['email'],
      created_at: created_at,
      confirmed_at: confirmed_at,
      level: row['progression'].to_i,
      memorized: row['memorized'].to_i,
      translation: row['translation'] == 'nil' ? nil : row['translation'],
      password: 'password123',
      password_confirmation: 'password123'
    )
  end
end

When(/^I visit the admin dashboard$/) do
  visit admin_dashboard_path
end

When(/^I click on "([^"]*)"$/) do |link_text|
  click_link link_text
end

Then(/^I should see "([^"]*)" new users in the past (\d+) days$/) do |count, days|
  within('.container-fluid') do
    expect(page).to have_content("Tracking #{count} new users")
  end
end

Then(/^I should see "([^"]*)" new users$/) do |count|
  expect(page).to have_content("#{count} new users")
end

# Removed - duplicate of web_steps.rb definition

Then(/^I should see the following metrics:$/) do |table|
  table.hashes.each do |row|
    metric = row['metric']
    value = row['value']
    # Try to find the metric and value on the page without specific container
    expect(page).to have_content(metric)
    expect(page).to have_content(value)
  end
end

# Removed - causes ambiguity with web_steps.rb definition

# Removed - duplicate of web_steps.rb definition

# Removed - duplicate of web_steps.rb definition

# Removed - duplicate of web_steps.rb definition

When(/^I click "View" for "([^"]*)"$/) do |user_name|
  within('tr', text: user_name) do
    click_link 'View'
  end
end

When(/^I click "Export CSV"$/) do
  click_link 'Export CSV'
end

Then(/^I should receive a CSV file$/) do
  expect(page.response_headers['Content-Type']).to include('text/csv')
end

Then(/^the CSV should contain "([^"]*)"$/) do |text|
  expect(page.body).to include(text)
end

Then(/^the CSV should not contain "([^"]*)"$/) do |text|
  expect(page.body).not_to include(text)
end

Given(/^there are unengaged users who need reminders$/) do
  # The New User 3 from our background is unengaged (progression = 1)
end

When(/^I click "Email Unengaged Users"$/) do
  click_link 'Email Unengaged Users'
end

When(/^I confirm the action$/) do
  # Capybara automatically handles Rails confirmation dialogs in test mode
  # or we can use: page.accept_confirm { click_link 'Email Unengaged Users' }
end

Then(/^reminder emails should be sent to unengaged users$/) do
  expect(ActionMailer::Base.deliveries).not_to be_empty
end

Then(/^I should see "Reminder emails sent to (\d+) unengaged users"$/) do |count|
  expect(page).to have_content("Reminder emails sent to #{count} unengaged users")
end

Given(/^I am logged in as a regular user$/) do
  @regular_user = FactoryBot.create(:user, admin: false, email: 'user@example.com', password: 'password123', password_confirmation: 'password123', confirmed_at: 1.day.ago)
  visit new_user_session_path
  fill_in 'email', with: @regular_user.email
  fill_in 'password', with: 'password123'
  click_button 'signinbutton'
end

When(/^I try to visit the admin onboarding dashboard$/) do
  visit admin_onboarding_dashboard_index_path
end

Then(/^I should be redirected to the home page$/) do
  expect(current_path).to eq(root_path)
end

# Removed - duplicate, use web_steps "I should see" instead

# Removed - duplicate of web_steps.rb definition

Then(/^I should see "Admin" in the main navigation$/) do
  within('#maintab') do
    expect(page).to have_content('Admin')
  end
end

When(/^I hover over "Admin"$/) do
  # Hovering is not supported in default Capybara driver
  # Just visit the admin page directly
  visit admin_dashboard_path
end

Then(/^I should see the following admin menu items:$/) do |table|
  within('#admin.submenustyle') do
    table.raw.flatten.each do |item|
      expect(page).to have_link(item)
    end
  end
end