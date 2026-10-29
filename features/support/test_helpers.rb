# Test helpers for Cucumber tests to ensure clean state between scenarios

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
