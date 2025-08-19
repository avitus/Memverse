require 'capybara/rspec'
require 'selenium-webdriver'

# Register headless Chrome driver for JavaScript tests
Capybara.register_driver :selenium_chrome_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  
  # Use the new headless mode (Chrome 109+)
  options.add_argument('--headless=new')
  options.add_argument('--disable-gpu')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  options.add_argument('--window-size=1920,1080')
  options.add_argument('--disable-blink-features=AutomationControlled')
  
  # Disable images and CSS for faster tests (optional)
  # options.add_preference('profile.default_content_setting_values.images', 2)
  # options.add_preference('profile.default_content_setting_values.stylesheets', 2)
  
  # Auto-accept alerts
  options.add_preference('profile.default_content_setting_values.notifications', 1)
  
  Capybara::Selenium::Driver.new(app,
    browser: :chrome,
    options: options,
    clear_local_storage: true,
    clear_session_storage: true
  )
end

# Register a visible Chrome driver for debugging
Capybara.register_driver :selenium_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--window-size=1920,1080')
  options.add_argument('--disable-blink-features=AutomationControlled')
  
  Capybara::Selenium::Driver.new(app,
    browser: :chrome,
    options: options
  )
end

# Configure Capybara
Capybara.configure do |config|
  config.default_max_wait_time = 10
  config.default_normalize_ws = true
  config.server = :puma, { Silent: true }
  config.server_port = 9887 + ENV['TEST_ENV_NUMBER'].to_i
end

# Set default drivers
Capybara.default_driver = :rack_test
Capybara.javascript_driver = :selenium_chrome_headless

RSpec.configure do |config|
  # Include Devise and Warden helpers for authentication in feature tests
  config.include Warden::Test::Helpers, type: :feature
  config.include Devise::Test::IntegrationHelpers, type: :feature
  
  # Configure for feature tests with JavaScript
  config.before(:each, type: :feature) do |example|
    if example.metadata[:js]
      Capybara.current_driver = :selenium_chrome_headless
      
      # Use truncation strategy for JavaScript tests
      DatabaseCleaner[:active_record].strategy = :truncation, {except: %w[final_verses]}
    else
      Capybara.current_driver = :rack_test
    end
    
    # Enable Warden test mode for feature tests
    Warden.test_mode!
  end
  
  config.after(:each, type: :feature) do
    Capybara.use_default_driver
    Warden.test_reset!
  end
  
  # Include Capybara DSL for feature specs
  config.include Capybara::DSL, type: :feature
  
  # Handle Selenium errors gracefully
  config.around(:each, type: :feature, js: true) do |example|
    example.run
  rescue Selenium::WebDriver::Error::UnknownError => e
    if e.message.include?('Failed to decode response from marionette')
      puts "Warning: Marionette decoding error, retrying..."
      Capybara.reset_sessions!
      sleep 1
      retry if (@retries ||= 0) < 1
      @retries += 1
    else
      raise
    end
  end
end