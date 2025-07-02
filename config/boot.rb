require 'rubygems'

# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require 'bundler/setup' if File.exist?(ENV['BUNDLE_GEMFILE'])

# Require dalli for cache store support
begin
  require 'dalli'
rescue LoadError
  # Dalli not available, will use fallback cache stores
end
