#!/usr/bin/env ruby

# Script to help set up database credentials for Rails 7.1

require 'pathname'
require 'yaml'
require 'fileutils'

puts "=" * 60
puts "Rails Database Credentials Setup"
puts "=" * 60
puts

# Check if we're in a Rails project
unless File.exist?('config/application.rb')
  puts "Error: This script must be run from the Rails project root directory"
  exit 1
end

# Check if master.key exists
unless File.exist?('config/master.key')
  puts "Error: config/master.key not found!"
  puts "This file is required to encrypt/decrypt credentials."
  exit 1
end

puts "This script will help you set up database credentials the modern Rails way."
puts
puts "You'll need:"
puts "1. Your production database password"
puts "2. (Optional) Any other database credentials"
puts
print "Do you want to continue? (y/n): "
exit unless gets.chomp.downcase == 'y'

puts
print "Enter your production database password: "
db_password = gets.chomp

print "Enter your production database username (default: memverse): "
db_username = gets.chomp
db_username = "memverse" if db_username.empty?

print "Enter your production database host (default: localhost): "
db_host = gets.chomp
db_host = "localhost" if db_host.empty?

puts
puts "Setting up credentials..."
puts

# Create a temporary file with the new credentials
temp_file = 'config/credentials_temp.yml'

# Read existing credentials
existing_content = `EDITOR="cat" rails credentials:show 2>/dev/null`
existing_yaml = YAML.safe_load(existing_content) || {}

# Add database credentials
existing_yaml['database'] = {
  'username' => db_username,
  'password' => db_password,
  'host' => db_host
}

# Write to temp file
File.write(temp_file, existing_yaml.to_yaml)

# Use Rails to encrypt the credentials
system("EDITOR='cp config/credentials_temp.yml' rails credentials:edit")

# Clean up temp file
FileUtils.rm_f(temp_file)

puts
puts "✓ Credentials have been updated!"
puts
puts "To verify, run:"
puts "  rails console"
puts "  Rails.application.credentials.database"
puts
puts "Next steps:"
puts "1. Update config/database.yml to use the modern configuration"
puts "2. Copy config/master.key to your production server"
puts "3. Deploy your application"
puts
puts "=" * 60