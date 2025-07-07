# Forum-specific step definitions

Given /^I am on the forum home page$/ do
  visit '/forum'
end

When /^I go to the forum home page$/ do
  visit '/forum'
end

# Alternative step to avoid ambiguity with generic web_steps
When /^I navigate to the forum home page$/ do
  visit '/forum'
end

Then /^I should see the forum navigation$/ do
  page.should have_content("Forums")
  page.should have_content("Messageboards")
end

Then /^I should see the new topic button$/ do
  page.should have_content("New Topic")
end

Then /^I should see the forum admin section$/ do
  page.should have_content("Admin")
end 