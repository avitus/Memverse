Given(/^I am logged in as an admin user$/) do
  @admin_user = FactoryBot.create(:user, admin: true, email: 'admin@example.com', password: 'password123')
  visit new_user_session_path
  fill_in 'Email', with: @admin_user.email
  fill_in 'Password', with: 'password123'
  click_button 'Sign in'
end

Given(/^the following users exist:$/) do |table|
  table.hashes.each do |row|
    created_at = eval(row['created_at'])
    confirmed_at = row['confirmed_at'] == 'nil' ? nil : eval(row['confirmed_at'])
    
    FactoryBot.create(:user,
      name: row['name'],
      email: row['email'],
      created_at: created_at,
      confirmed_at: confirmed_at,
      progression: row['progression'].to_i,
      memorized: row['memorized'].to_i,
      translation: row['translation'] == 'nil' ? nil : row['translation']
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

# This step is already defined in web_steps.rb
# Then(/^I should not see "([^"]*)"$/) do |text|
#   expect(page).not_to have_content(text)
# end

Then(/^I should see the following metrics:$/) do |table|
  table.hashes.each do |row|
    metric = row['metric']
    value = row['value']
    within('.card', text: metric) do
      expect(page).to have_content(value)
    end
  end
end

Given(/^I am on the onboarding dashboard page$/) do
  visit admin_onboarding_dashboard_index_path
end

When(/^I select "([^"]*)" from "([^"]*)"$/) do |option, field|
  select option, from: field
end

When(/^I click "([^"]*)"$/) do |button|
  click_button button
end

# This step is already defined in web_steps.rb
# Then(/^I should see "([^"]*)"$/) do |text|
#   expect(page).to have_content(text)
# end

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
  @regular_user = FactoryBot.create(:user, admin: false, email: 'user@example.com', password: 'password123')
  visit new_user_session_path
  fill_in 'Email', with: @regular_user.email
  fill_in 'Password', with: 'password123'
  click_button 'Sign in'
end

When(/^I try to visit the admin onboarding dashboard$/) do
  visit admin_onboarding_dashboard_index_path
end

Then(/^I should be redirected to the home page$/) do
  expect(current_path).to eq(root_path)
end

Then(/^I should see "You must be an admin to access this page"$/) do
  expect(page).to have_content('You must be an admin to access this page')
end

Given(/^I am on the home page$/) do
  visit root_path
end

Then(/^I should see "Admin" in the main navigation$/) do
  within('#maintab') do
    expect(page).to have_content('Admin')
  end
end

When(/^I hover over "Admin"$/) do
  find('li[rel="admin"]').hover
end

Then(/^I should see the following admin menu items:$/) do |table|
  within('#admin.submenustyle') do
    table.raw.flatten.each do |item|
      expect(page).to have_link(item)
    end
  end
end