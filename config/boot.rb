ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.

# Fix for Ruby 3.2+ Logger constant issue
# In Ruby 3.2, the Logger class was moved to a separate gem and needs to be
# explicitly required before ActiveSupport tries to use Logger::Severity
begin
  require "logger"
rescue LoadError
  # Logger should be available in Ruby 3.2+, but handle gracefully if not
end
