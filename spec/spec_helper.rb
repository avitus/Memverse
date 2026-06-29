# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'database_cleaner'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :rspec

  # Add ActiveSupport time helpers for time travel in tests
  config.include ActiveSupport::Testing::TimeHelpers

  # Add metadata to specs based on file location
  config.infer_spec_type_from_file_location!

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_paths = [Rails.root.join("spec/fixtures").to_s]

  # Disable transactional fixtures since we're using DatabaseCleaner
  config.use_transactional_fixtures = false

  # Use color in STDOUT
  config.color = true

  # Use color not only in STDOUT but also in pagers and files
  config.tty = true

  # Use the specified formatter
  config.formatter = :documentation # :progress, :html, :textmate

  # Configure devise helpers
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include ControllerMacros,                type: :controller  # ALV: need to use 'include' and not 'extend' as indicated in Devise Wiki
  config.include Requests::JsonHelpers,           type: :controller  # ALV: helpers for testing API

  # RocketPants test helpers removed - using Rails API mode instead
  # config.include RocketPants::TestHelper,    :type => :controller
  # config.include RocketPants::RSpecMatchers, :type => :controller

end

Capybara.default_host = 'localhost:3000'
Capybara.server = :puma

# ALV: Added this in an attempt to solve Net::ReadTimeout errors that only occur on CircleCI
# Capybara.register_driver :selenium do |app|
#   profile = Selenium::WebDriver::Firefox::Profile.new
#   client = Selenium::WebDriver::Remote::Http::Default.new
#   client.timeout = 120 # instead of the default 60
#   Capybara::Selenium::Driver.new(app, browser: :firefox, profile: profile, http_client: client)
# end

# Capybara.register_driver :chrome do |app|
#   client = Selenium::WebDriver::Remote::Http::Default.new
#   client.read_timeout = 120

#   Capybara::Selenium::Driver.new(app, {browser: :chrome, http_client: client})
# end

# ALV - this doesn't work either
# Capybara.register_driver :chrome do |app|
#   Capybara::Selenium::Driver.new(app, :browser => :chrome)
# end

# Capybara.javascript_driver = :chrome

Capybara.register_driver :custom_chrome_headless do |app|
  browser_options = ::Selenium::WebDriver::Chrome::Options.new()
  browser_options.args << '--headless'
  browser_options.args << '--no-sandbox'
  browser_options.args << '--disable-gpu'
  browser_options.args << '--window-size=1920,1080'
  Capybara::Selenium::Driver.new(app,
    browser: :chrome,
    options: browser_options
  )
end

