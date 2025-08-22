# Test helpers for Cucumber tests to ensure clean state and proper waits

module TestHelpers
  # Ensure clean browser session between scenarios
  def ensure_clean_session
    Capybara.reset_sessions!
    
    # Clear browser cookies if using Selenium
    if page.driver.browser.respond_to?(:manage)
      page.driver.browser.manage.delete_all_cookies rescue nil
    end
    
    # Clear local storage and session storage for JavaScript tests
    if Capybara.current_driver == :selenium_chrome_headless
      page.execute_script('window.localStorage.clear();') rescue nil
      page.execute_script('window.sessionStorage.clear();') rescue nil
    end
  end
  
  # Wait for all AJAX requests to complete
  def wait_for_ajax
    return unless page.respond_to?(:evaluate_script)
    
    Timeout.timeout(Capybara.default_max_wait_time) do
      loop until finished_all_ajax_requests?
    end
  rescue Timeout::Error
    # Ajax requests didn't finish in time, but continue test
    puts "Warning: Ajax requests did not complete within timeout"
  end
  
  # Check if all jQuery AJAX requests are finished
  def finished_all_ajax_requests?
    return true unless page.evaluate_script('typeof jQuery !== "undefined"')
    page.evaluate_script('jQuery.active').zero?
  rescue Capybara::NotSupportedByDriverError
    true
  end
  
  # Wait for page to be fully loaded
  def wait_for_page_load
    return unless page.respond_to?(:evaluate_script)
    
    Timeout.timeout(Capybara.default_max_wait_time) do
      loop until page_loaded?
    end
  rescue Timeout::Error
    puts "Warning: Page did not finish loading within timeout"
  end
  
  # Check if page is fully loaded
  def page_loaded?
    page.evaluate_script('document.readyState') == 'complete'
  rescue Capybara::NotSupportedByDriverError
    true
  end
  
  # Wait for a specific element to be visible
  def wait_for_element(selector, options = {})
    timeout = options[:timeout] || Capybara.default_max_wait_time
    
    Timeout.timeout(timeout) do
      loop until page.has_selector?(selector, visible: true)
    end
  rescue Timeout::Error
    raise "Element '#{selector}' was not visible within #{timeout} seconds"
  end
  
  # Safely execute JavaScript with fallback
  def safe_execute_script(script)
    return unless page.respond_to?(:execute_script)
    page.execute_script(script)
  rescue Capybara::NotSupportedByDriverError
    # Driver doesn't support JavaScript, skip
  rescue Selenium::WebDriver::Error::JavascriptError => e
    puts "JavaScript error: #{e.message}"
  end
  
  # Retry a block of code with exponential backoff
  def with_retry(times: 3, delay: 1)
    attempt = 0
    begin
      attempt += 1
      yield
    rescue StandardError => e
      if attempt < times
        sleep(delay * attempt)
        retry
      else
        raise e
      end
    end
  end
  
  # Handle database connection issues
  def with_db_connection
    ActiveRecord::Base.connection.reconnect! unless ActiveRecord::Base.connection.active?
    yield
  rescue ActiveRecord::ConnectionNotEstablished
    ActiveRecord::Base.establish_connection
    retry
  end
  
  # Clean up test data without affecting seed data
  def clean_test_data
    with_db_connection do
      # Only delete data created during tests, preserve seed data
      User.where('created_at > ?', 1.hour.ago).destroy_all
      Memverse.where('created_at > ?', 1.hour.ago).destroy_all
      Verse.where('created_at > ?', 1.hour.ago).destroy_all
    end
  end
end

# Make helpers available in Cucumber steps
World(TestHelpers)

# Add hooks to ensure clean state
Before do
  ensure_clean_session
end

After do |scenario|
  # Take screenshot on failure for debugging
  if scenario.failed? && Capybara.current_driver == :selenium_chrome_headless
    timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
    screenshot_path = "tmp/screenshots/#{scenario.name.gsub(/[^a-zA-Z0-9]/, '_')}_#{timestamp}.png"
    FileUtils.mkdir_p('tmp/screenshots')
    page.save_screenshot(screenshot_path)
    puts "Screenshot saved: #{screenshot_path}"
  end
  
  # Ensure clean state for next scenario
  ensure_clean_session
end