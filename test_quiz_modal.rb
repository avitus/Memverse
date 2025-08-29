#!/usr/bin/env ruby
require 'net/http'
require 'uri'
require 'json'

# Test script to verify welcome modal fix
# This script checks if the welcome modal JavaScript is properly contained
# within the conditional block when viewing the quiz schedule

puts "Testing Live Quiz Welcome Modal Fix..."
puts "=" * 50

# Login to get a session
uri = URI.parse("http://localhost:3000/users/sign_in")
http = Net::HTTP.new(uri.host, uri.port)

# Get CSRF token
response = http.get(uri.path)
csrf_token = response.body.match(/name="authenticity_token" value="([^"]+)"/)[1] rescue nil

if csrf_token.nil?
  puts "ERROR: Could not get CSRF token"
  exit 1
end

# Create session cookie jar
cookie = response['set-cookie']

# Login as test user
login_data = URI.encode_www_form({
  'user[email]' => 'test@example.com',
  'user[password]' => 'password123',
  'authenticity_token' => csrf_token
})

request = Net::HTTP::Post.new(uri.path)
request['Cookie'] = cookie
request['Content-Type'] = 'application/x-www-form-urlencoded'
request.body = login_data

response = http.request(request)
cookie = response['set-cookie'] || cookie

# Check /live_quiz when no quiz is scheduled
puts "\n1. Testing /live_quiz when no quiz is scheduled:"
uri = URI.parse("http://localhost:3000/live_quiz")
request = Net::HTTP::Get.new(uri.path)
request['Cookie'] = cookie
response = http.request(request)

if response.code == "200"
  body = response.body
  
  # Check if we're showing the schedule
  has_schedule = body.include?("quiz-schedule-compact") || body.include?("Weekly Schedule")
  has_quiz_interface = body.include?("live-quiz") && body.include?("data-controller=\"live-quiz\"")
  has_welcome_modal_js = body.include?("openContentModal") && body.include?("welcome-box")
  
  puts "   - Response code: #{response.code} ✓"
  puts "   - Has schedule view: #{has_schedule ? '✓' : '✗'}"
  puts "   - Has quiz interface: #{has_quiz_interface ? '✗ (should not show)' : '✓'}"
  puts "   - Has welcome modal JS: #{has_welcome_modal_js ? '✗ (should not show)' : '✓'}"
  
  if has_schedule && !has_quiz_interface && !has_welcome_modal_js
    puts "\n   SUCCESS: Schedule is shown without quiz interface or modal JS"
  else
    puts "\n   FAILURE: Conditional logic not working properly"
    
    # Debug: Show what's actually in the response
    if has_welcome_modal_js
      puts "\n   DEBUG: Found modal JavaScript that shouldn't be there:"
      modal_snippet = body.match(/.{0,100}openContentModal.{0,100}/m)
      puts "   #{modal_snippet[0]}" if modal_snippet
    end
  end
else
  puts "   - Response code: #{response.code} ✗"
end

puts "\n" + "=" * 50
puts "Test complete."