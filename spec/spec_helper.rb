require 'rubygems'
require 'spork'
#uncomment the following line to use spork with the debugger
#require 'spork/ext/ruby-debug'

Spork.prefork do
  # Loading more in this block will cause your tests to run faster. However,
  # if you change any configuration or code from libraries loaded here, you'll
  # need to restart spork for it take effect.

end

Spork.each_run do
  # This code will be run each time you run your specs.

end

# --- Instructions ---
# Sort the contents of this file into a Spork.prefork and a Spork.each_run
# block.
#
# The Spork.prefork block is run only once when the spork server is started.
# You typically want to place most of your (slow) initializer code in here, in
# particular, require'ing any 3rd-party gems that you don't normally modify
# during development.
#
# The Spork.each_run block is run each time you run your specs.  In case you
# need to load files that tend to change during development, require them here.
# With Rails, your application modules are loaded automatically, so sometimes
# this block can remain empty.
#
# Note: You can modify files loaded *from* the Spork.each_run block without
# restarting the spork server.  However, this file itself will not be reloaded,
# so if you change any of the code inside the each_run block, you still need to
# restart the server.  In general, if you have non-trivial code in this file,
# it's advisable to move it into a separate file so you can easily edit it
# without restarting spork.  (For example, with RSpec, you could move
# non-trivial code into a file spec/support/my_helper.rb, making sure that the
# spec/support/* files are require'd from inside the each_run block.)
#
# Any code that is left outside the two blocks will be run during preforking
# *and* during each_run -- that's probably not what you want.
#
# These instructions should self-destruct in 10 seconds.  If they don't, feel
# free to delete them.




# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'

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

  # Add metadata to specs based on file location
  config.infer_spec_type_from_file_location!

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

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

  # Add support for RocketPants test helpers
  config.include RocketPants::TestHelper,    :type => :controller
  config.include RocketPants::RSpecMatchers, :type => :controller

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

