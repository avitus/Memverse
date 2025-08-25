# Helper methods for proper waiting in Cucumber tests
# These replace hard-coded sleep statements with proper Capybara waits

module WaitHelpers
  # Wait for a specific condition with custom timeout
  def wait_for(timeout: Capybara.default_max_wait_time)
    Timeout.timeout(timeout) do
      loop until yield
      sleep 0.1
    end
  rescue Timeout::Error
    false
  end
  
  # Wait for authentication to be fully established
  def wait_for_authentication
    expect(page).to have_content('Logout', wait: 5)
    wait_for_ajax if page.respond_to?(:evaluate_script)
  end
  
  # Wait for forum to be fully loaded
  def wait_for_forum_load
    # Wait for either the main forum container or messageboards
    wait_for(timeout: 3) do
      page.has_css?('.thredded--main') || page.has_content?('Messageboards') || page.has_content?('Feedback')
    end
    wait_for_ajax if page.respond_to?(:evaluate_script)
  end
  
  # Wait for voting interface to be ready
  def wait_for_voting_interface
    expect(page).to have_css('.thredded-voting', wait: 3)
    wait_for_ajax if page.respond_to?(:evaluate_script)
  end
  
  # Wait for vote button to be clickable
  def wait_and_click_vote_button(button_type)
    selector = ".vote-button.#{button_type}"
    expect(page).to have_css(selector, wait: 3)
    
    # Ensure button is visible and clickable
    button = find(selector, wait: 2)
    
    button.click
    wait_for_ajax if page.respond_to?(:evaluate_script)
  end
  
  # Re-authenticate if session is lost
  def ensure_authenticated(user = @current_user)
    return if page.has_content?('Logout', wait: 2)
    
    if user
      visit '/users/sign_in'
      fill_in 'user[email]', with: user.email
      fill_in 'user[password]', with: 'password123'
      
      # Try different button texts
      button_texts = ['Sign in', 'Log in', 'Login', 'commit']
      button_texts.each do |text|
        if page.has_button?(text)
          click_button text
          break
        end
      end
      
      wait_for_authentication
    end
  end
  
  # Navigate to topic with proper waiting
  def navigate_to_topic(topic_title)
    topic = Thredded::Topic.find_by!(title: topic_title)
    
    # Navigate through forum properly for JavaScript tests
    if Capybara.current_driver != :rack_test
      visit '/forum'
      wait_for_forum_load
      
      # Navigate to the messageboard
      if page.has_link?(topic.messageboard.name, wait: 5)
        click_link(topic.messageboard.name)
      else
        visit "/forum/#{topic.messageboard.slug}"
      end
      
      # Wait for topics to load and click the specific topic
      expect(page).to have_content(topic_title, wait: 10)
      
      if page.has_link?(topic_title)
        click_link(topic_title)
      else
        find('a', text: /#{Regexp.escape(topic_title)}/i).click
      end
      
      # Verify we're on the topic page
      expect(page).to have_content(topic_title, wait: 10)
      wait_for_ajax if page.respond_to?(:evaluate_script)
    else
      # Direct navigation for non-JavaScript tests
      visit "/forum/#{topic.messageboard.slug}/#{topic.slug}"
    end
  end
  
  # Wait for vote action to complete
  def wait_for_vote_update
    wait_for_ajax if page.respond_to?(:evaluate_script)
    
    # Wait for score to update
    wait_for(timeout: 5) do
      page.has_css?('.vote-score')
    end
  end
end

World(WaitHelpers)