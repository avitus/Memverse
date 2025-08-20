# Forum voting specific step definitions

# Forum voting specific step definitions
# Note: This file only contains steps specific to forum voting.
# General steps like login/logout are in user_steps.rb and web_steps.rb

# Reuse existing steps where possible
Given('I have a user account') do
  @user = FactoryBot.create(:user, password: 'password123', password_confirmation: 'password123')
end

Given('I am logged in') do
  @current_user = @user || FactoryBot.create(:user, password: 'password123', password_confirmation: 'password123')
  step %{I sign in as "#{@current_user.email}/password123"}
end

Given('there is a feedback messageboard') do
  @feedback_board = Thredded::Messageboard.create!(
    name: 'Feedback & Feature Requests',
    slug: 'feedback',
    description: 'Vote on features'
  )
end

Given('there is a general discussion board') do
  @general_board = Thredded::Messageboard.create!(
    name: 'General Discussion',
    slug: 'general',
    description: 'General topics'
  )
end

Given('the following feedback topics exist:') do |table|
  table.hashes.each do |row|
    author = User.find_by(login: row['author']) || FactoryBot.create(:user, login: row['author'], password: 'password123', password_confirmation: 'password123')
    
    topic = nil
    Thredded::Topic.transaction do
      topic = Thredded::Topic.create!(
        messageboard: @feedback_board,
        user: author,
        title: row['title'],
        sticky: false,
        locked: false
      )
      
      Thredded::Post.create!(
        postable: topic,
        user: author,
        content: "Initial content for #{row['title']}",
        messageboard: @feedback_board
      )
    end
    
    # Add votes
    row['votes_up'].to_i.times do |i|
      voter = FactoryBot.create(:user, login: "upvoter_#{i}_#{topic.id}", password: 'password123', password_confirmation: 'password123')
      voter.likes topic
    end
    
    row['votes_down'].to_i.times do |i|
      voter = FactoryBot.create(:user, login: "downvoter_#{i}_#{topic.id}", password: 'password123', password_confirmation: 'password123')
      voter.dislikes topic
    end
    
  end
end

Given('there is a topic {string} in the general board') do |title|
  author = FactoryBot.create(:user, password: 'password123', password_confirmation: 'password123')
  topic = nil
  Thredded::Topic.transaction do
    topic = Thredded::Topic.create!(
      messageboard: @general_board,
      user: author,
      title: title,
      sticky: false,
      locked: false
    )
    
    Thredded::Post.create!(
      postable: topic,
      user: author,
      content: "Content for #{title}",
      messageboard: @general_board
    )
  end
end

Given('I have upvoted {string}') do |topic_title|
  topic = Thredded::Topic.find_by!(title: topic_title)
  @current_user.likes topic
end

Given('I have downvoted {string}') do |topic_title|
  topic = Thredded::Topic.find_by!(title: topic_title)
  @current_user.dislikes topic
end

Given('I am logged in as {string}') do |username|
  @current_user = FactoryBot.create(:user, login: username, password: 'password123', password_confirmation: 'password123')
  @current_user.confirm # Ensure user is confirmed for Devise
  @current_user.save!
  step %{I sign in as "#{@current_user.email}/password123"}
end

When('I visit the feedback board') do
  visit '/forum'
  
  # For JavaScript tests, we might need to wait longer for redirects
  if Capybara.current_driver != :rack_test
    sleep 2
    
    # Check if we got redirected and need to visit forum again
    unless current_url.include?('/forum') || page.has_content?('Messageboards')
      visit '/forum'
      sleep 1
    end
  end
  
  # Now try to access the feedback messageboard
  if page.has_link?('Feedback & Feature Requests')
    click_link('Feedback & Feature Requests')
  elsif page.has_content?('Messageboards')
    # We're on the forum home page, let's try navigating properly
    # Try to find and click on feedback link
    within('.thredded--main') do
      click_link('Feedback & Feature Requests') if page.has_link?('Feedback & Feature Requests')
    end
  else
    # Direct navigation to messageboard
    visit '/forum/feedback'
  end
  
  # Wait for topics to load
  if Capybara.current_driver != :rack_test
    # Wait for any topic to be visible (case insensitive)
    expect(page).to have_content(/add dark mode|mobile app|export|improve/i, wait: 10) 
  end
end

When('I visit the general discussion board') do
  visit '/forum'
  
  # For JavaScript tests, wait for page load
  if Capybara.current_driver != :rack_test
    sleep 2
    unless current_url.include?('/forum') || page.has_content?('Messageboards')
      visit '/forum'
      sleep 1
    end
  end
  
  # Navigate to general discussion board
  if page.has_link?('General Discussion')
    click_link('General Discussion')
  else
    visit '/forum/general'
  end
end

When('I visit the topic {string}') do |topic_title|
  topic = Thredded::Topic.find_by!(title: topic_title)
  
  # For JavaScript tests, navigate through the forum properly
  if Capybara.current_driver != :rack_test
    visit '/forum'
    sleep 2
    unless current_url.include?('/forum') || page.has_content?('Messageboards')
      visit '/forum'
      sleep 1
    end
    
    # Navigate to the messageboard first
    if page.has_link?(topic.messageboard.name)
      click_link(topic.messageboard.name)
    else
      visit "/forum/#{topic.messageboard.slug}"
    end
    
    # Wait for topics to load and then click the specific topic
    expect(page).to have_content(topic_title, wait: 10)
    click_on_topic(topic_title)
    
    # Verify we're on the topic page
    expect(page).to have_content(topic_title, wait: 10)
    expect(current_url).to include(topic.slug)
  else
    # For non-JavaScript tests, direct navigation should work
    visit "/forum/#{topic.messageboard.slug}/#{topic.slug}"
  end
end

# Helper method for clicking topics
def click_on_topic(topic_title)
  if page.has_link?(topic_title)
    click_link(topic_title)
  else
    # Look for a link that contains the topic title
    topic_link = find('a', text: /#{Regexp.escape(topic_title)}/i)
    topic_link.click
  end
end

When('I visit the topic {string} in the general board') do |topic_title|
  topic = Thredded::Topic.find_by!(title: topic_title)
  visit "/forum/general/#{topic.slug}"
end

When('I click the upvote button') do
  # Wait for the voting interface to be present
  expect(page).to have_css('.vote-button.upvote', wait: 10)
  find('.vote-button.upvote').click
  # Wait for the AJAX response to complete and page to update
  sleep 2
end

When('I click the downvote button') do
  # Wait for the voting interface to be present
  expect(page).to have_css('.vote-button.downvote', wait: 10)
  find('.vote-button.downvote').click
  # Wait for the AJAX response to complete and page to update
  sleep 2
end

When('I log in as {string}') do |username|
  step "I am logged in as \"#{username}\""
end

When('I log in again') do
  step %{I sign in as "#{@current_user.email}/password123"}
end

When('I log out') do
  step %{I am not logged in}
end

When('I remove my vote') do
  # Wait for the remove vote link to be present
  expect(page).to have_link('remove vote', wait: 10)
  click_link('remove vote')
  # Wait for the AJAX response to complete and page to update
  sleep 3
end

When('I click on the topic {string}') do |topic_title|
  # Wait for the topic to be visible
  expect(page).to have_content(topic_title, wait: 10)
  click_on_topic(topic_title)
end

Then('I should see vote counts on topics') do
  expect(page).to have_css('.badge', minimum: 1)
end

Then('I should not see voting buttons') do
  expect(page).not_to have_css('.vote-button')
end

Then('I should see the vote score is {string}') do |score|
  expect(page).to have_css('.vote-score', text: score, wait: 10)
end

Then('the upvote button should be highlighted') do
  expect(page).to have_css('.vote-button.upvote.voted', wait: 10)
end

Then('the downvote button should be highlighted') do
  expect(page).to have_css('.vote-button.downvote.voted', wait: 10)
end

Then('the upvote button should not be highlighted') do
  expect(page).not_to have_css('.vote-button.upvote.voted')
end

Then('no vote buttons should be highlighted') do
  expect(page).not_to have_css('.vote-button.voted')
end

Then('I should see topics in order:') do |table|
  topic_titles = all('.thredded--topics--title').map(&:text)
  expected_titles = table.raw.flatten
  
  expected_titles.each_with_index do |title, index|
    expect(topic_titles[index]).to eq(title)
  end
end

Then('I should see {string} for {string}') do |vote_text, topic_title|
  topic = Thredded::Topic.find_by!(title: topic_title)
  within("article[data-topic='#{topic.id}']") do
    expect(page).to have_content(vote_text)
  end
end

Then('I should not see a vote badge for {string}') do |topic_title|
  topic = Thredded::Topic.find_by!(title: topic_title)
  within("article[data-topic='#{topic.id}']") do
    expect(page).not_to have_css('.badge')
  end
end

Then('I should not see voting interface') do
  expect(page).not_to have_css('.thredded-voting')
end

Then('I should not see vote badges') do
  expect(page).not_to have_css('.badge')
end