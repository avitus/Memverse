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
  
  # Wait for authentication state to be established
  expect(page).to have_content('Logout', wait: 10)
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
  table.hashes.each_with_index do |row, index|
    author = User.find_by(login: row['author']) || FactoryBot.create(:user, login: row['author'], password: 'password123', password_confirmation: 'password123')
    
    topic = nil
    Thredded::Topic.transaction do
      # Set created_at to ensure consistent ordering
      created_time = index.hours.ago
      topic = Thredded::Topic.create!(
        messageboard: @feedback_board,
        user: author,
        title: row['title'],
        sticky: false,
        locked: false,
        created_at: created_time,
        updated_at: created_time
      )
      
      Thredded::Post.create!(
        postable: topic,
        user: author,
        content: "Initial content for #{row['title']}",
        messageboard: @feedback_board,
        created_at: created_time,
        updated_at: created_time
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
  @current_topic_title = topic_title  # Store for potential re-navigation
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
    
    # Wait a moment for the voting interface to render if user is logged in
    sleep 1 if page.has_content?('Logout')
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
  # For JavaScript tests, ensure we're authenticated and voting interface is available
  if Capybara.current_driver != :rack_test
    # Check authentication state multiple times with retries
    max_retries = 3
    retries = 0
    
    while retries < max_retries
      # Check if we're authenticated
      if page.has_content?('Login to vote', wait: 2) || !page.has_content?('Logout', wait: 2)
        # Session may be lost, re-authenticate
        if @current_user
          puts "Re-authenticating user #{@current_user.email} (attempt #{retries + 1})"
          visit '/users/sign_in'
          fill_in 'user[email]', with: @current_user.email
          fill_in 'user[password]', with: 'password123'
          # Try different button texts that might exist
          if page.has_button?('Sign in')
            click_button 'Sign in'
          elsif page.has_button?('Log in')
            click_button 'Log in'
          elsif page.has_button?('Login')
            click_button 'Login'
          else
            click_button 'commit'  # Default form submit
          end
          
          # Wait for authentication to be established
          expect(page).to have_content('Logout', wait: 15)
          sleep 2
          
          # Navigate back to the current page if needed
          unless current_url.include?('/topics/')
            # We need to get back to the topic page
            topic_title = @current_topic_title if @current_topic_title
            if topic_title
              step %{I visit the topic "#{topic_title}"}
            else
              page.refresh
              sleep 3
            end
          else
            page.refresh
            sleep 3
          end
        else
          raise "No current user available to re-authenticate"
        end
      else
        # We appear to be authenticated, break out of retry loop
        break
      end
      
      retries += 1
    end
    
    # Final authentication check
    expect(page).to have_content('Logout', wait: 10)
    
    # Wait for the voting interface to load with retries
    voting_interface_found = false
    3.times do |attempt|
      if page.has_css?('.thredded-voting', wait: 5)
        if page.has_css?('.vote-button.upvote', wait: 5)
          voting_interface_found = true
          break
        else
          puts "Voting interface found but upvote button missing (attempt #{attempt + 1})"
          sleep 2
          page.refresh
          sleep 3
        end
      else
        puts "Voting interface not found (attempt #{attempt + 1})"
        sleep 2
        page.refresh
        sleep 3
      end
    end
    
    unless voting_interface_found
      puts "Page content: #{page.body[0..1000]}"
      raise "Voting interface not found after retries"
    end
  end
  
  # Click the upvote button
  expect(page).to have_css('.vote-button.upvote', wait: 10)
  find('.vote-button.upvote').click
  
  # Wait for the AJAX response to complete and page to update
  sleep 3
end

When('I click the downvote button') do
  # For JavaScript tests, ensure we're authenticated and voting interface is available
  if Capybara.current_driver != :rack_test
    # Check authentication state with retries (similar to upvote)
    max_retries = 3
    retries = 0
    
    while retries < max_retries
      # Check if we're authenticated
      if page.has_content?('Login to vote', wait: 2) || !page.has_content?('Logout', wait: 2)
        # Session may be lost, re-authenticate
        if @current_user
          puts "Re-authenticating user for downvote #{@current_user.email} (attempt #{retries + 1})"
          visit '/users/sign_in'
          fill_in 'user[email]', with: @current_user.email
          fill_in 'user[password]', with: 'password123'
          # Try different button texts that might exist
          if page.has_button?('Sign in')
            click_button 'Sign in'
          elsif page.has_button?('Log in')
            click_button 'Log in'
          elsif page.has_button?('Login')
            click_button 'Login'
          else
            click_button 'commit'  # Default form submit
          end
          
          # Wait for authentication to be established
          expect(page).to have_content('Logout', wait: 15)
          sleep 2
          
          # Navigate back to the current page if needed
          unless current_url.include?('/topics/')
            topic_title = @current_topic_title if @current_topic_title
            if topic_title
              step %{I visit the topic "#{topic_title}"}
            else
              page.refresh
              sleep 3
            end
          else
            page.refresh
            sleep 3
          end
        else
          raise "No current user available to re-authenticate"
        end
      else
        # We appear to be authenticated, break out of retry loop
        break
      end
      
      retries += 1
    end
    
    # Final authentication check
    expect(page).to have_content('Logout', wait: 10)
    
    # Wait for the voting interface to load with retries
    voting_interface_found = false
    3.times do |attempt|
      if page.has_css?('.thredded-voting', wait: 5)
        if page.has_css?('.vote-button.downvote', wait: 5)
          voting_interface_found = true
          break
        else
          puts "Voting interface found but downvote button missing (attempt #{attempt + 1})"
          sleep 2
          page.refresh
          sleep 3
        end
      else
        puts "Voting interface not found for downvote (attempt #{attempt + 1})"
        sleep 2
        page.refresh
        sleep 3
      end
    end
    
    unless voting_interface_found
      puts "Page content: #{page.body[0..1000]}"
      raise "Voting interface not found for downvote after retries"
    end
  end
  
  # Click the downvote button
  expect(page).to have_css('.vote-button.downvote', wait: 10)
  find('.vote-button.downvote').click
  
  # Wait for the AJAX response to complete and page to update
  sleep 3
end

When('I log in as {string}') do |username|
  step "I am logged in as \"#{username}\""
  
  # Wait for authentication state to be established
  expect(page).to have_content('Logout', wait: 10)
  
  # Give extra time for session to be fully established
  sleep 1
end

When('I log in again') do
  step %{I sign in as "#{@current_user.email}/password123"}
  
  # Wait for authentication state to be established
  expect(page).to have_content('Logout', wait: 10)
end

When('I log out') do
  if Capybara.current_driver != :rack_test
    # Devise requires DELETE for sign_out, so visiting the URL via GET is unreliable.
    # Clear cookies directly to guarantee the session is destroyed.
    page.driver.browser.manage.delete_all_cookies
  else
    step %{I am not logged in}
  end
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

Then('I should not see the vote score is {string}') do |score|
  expect(page).not_to have_css('.vote-score', text: score)
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