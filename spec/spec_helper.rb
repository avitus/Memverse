# This file is copied to spec/ when you run 'rails generate rspec:install'

# Per-test coverage for CircleCI Smarter Testing test impact analysis; a no-op unless
# CIRCLECI_COVERAGE is set. Required before the Rails environment so code loaded at boot is tracked.
require 'rspec-circleci-coverage'

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

end

Capybara.default_host = 'localhost:3000'
Capybara.server = :puma

