# Custom Capybara configuration for handling JavaScript alerts and other issues

# Configure Selenium Chrome driver with proper options for stability and SPEED
Capybara.register_driver :selenium_chrome_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  
  # Use new headless mode for better compatibility
  options.add_argument('--headless=new')
  options.add_argument('--disable-gpu')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  options.add_argument('--window-size=1920,1080')
  
  # Disable animations and transitions for FASTER tests
  options.add_argument('--disable-web-animations')
  options.add_argument('--disable-smooth-scrolling')
  options.add_argument('--disable-blink-features=AutomationControlled')
  options.add_argument('--disable-site-isolation-trials')
  
  # Improve stability and speed in CI environment
  options.add_argument('--disable-features=VizDisplayCompositor')
  options.add_argument('--disable-background-timer-throttling')
  options.add_argument('--disable-backgrounding-occluded-windows')
  options.add_argument('--disable-renderer-backgrounding')
  options.add_argument('--disable-features=TranslateUI')
  options.add_argument('--disable-ipc-flooding-protection')
  
  # Faster page loads
  options.add_argument('--aggressive-cache-discard')
  options.add_argument('--disable-extensions')
  options.add_argument('--disable-default-apps')
  
  # Handle alerts automatically
  options.add_preference('profile.default_content_setting_values.notifications', 1)
  options.unhandled_prompt_behavior = :accept
  
  # Use eager page load strategy for faster test execution
  # 'eager' returns control as soon as DOM is ready (not waiting for images/stylesheets)
  options.page_load_strategy = 'eager'
  
  Capybara::Selenium::Driver.new(app, 
    browser: :chrome,
    options: options
  )
end

# Optimize timeouts - reduce wait times for faster failures
Capybara.default_max_wait_time = ENV['CI'] ? 5 : 3

# Configure Capybara to automatically accept JavaScript confirms and alerts
Capybara.automatic_reload = false

# Helper method to handle alerts in tests
def accept_alert
  page.driver.browser.switch_to.alert.accept
rescue Selenium::WebDriver::Error::NoSuchAlertError
  # No alert present, continue
end

# Helper method to dismiss alerts in tests
def dismiss_alert
  page.driver.browser.switch_to.alert.dismiss
rescue Selenium::WebDriver::Error::NoSuchAlertError
  # No alert present, continue
end

# Helper method to get alert text
def alert_text
  page.driver.browser.switch_to.alert.text
rescue Selenium::WebDriver::Error::NoSuchAlertError
  nil
end