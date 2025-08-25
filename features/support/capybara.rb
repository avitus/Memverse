# Custom Capybara configuration for handling JavaScript alerts and other issues

# Configure Selenium Chrome driver with proper options for stability
Capybara.register_driver :selenium_chrome_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  
  # Use new headless mode for better compatibility
  options.add_argument('--headless=new')
  options.add_argument('--disable-gpu')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  options.add_argument('--window-size=1920,1080')
  
  # Disable animations and transitions for more stable tests
  options.add_argument('--disable-web-animations')
  options.add_argument('--disable-smooth-scrolling')
  
  # Improve stability in CI environment
  options.add_argument('--disable-features=VizDisplayCompositor')
  options.add_argument('--disable-background-timer-throttling')
  options.add_argument('--disable-backgrounding-occluded-windows')
  options.add_argument('--disable-renderer-backgrounding')
  
  # Handle alerts automatically
  options.add_preference('profile.default_content_setting_values.notifications', 1)
  options.unhandled_prompt_behavior = :accept
  
  # Set page load strategy to ensure page is fully loaded
  options.page_load_strategy = 'normal'
  
  Capybara::Selenium::Driver.new(app, 
    browser: :chrome,
    options: options
  )
end

# Increase timeouts for CI environment
Capybara.default_max_wait_time = ENV['CI'] ? 15 : 10

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