#!/usr/bin/env ruby
# Quick verification that quiz is working

require 'open-uri'
require 'json'

puts "=== Verifying Quiz Functionality ==="
puts "Time: #{Time.now}"
puts ""

# 1. Check if quiz page loads
begin
  response = URI.open("http://localhost:3000/live_quiz/2")
  content = response.read
  
  puts "✓ Quiz page loads successfully"
  
  # Check for critical elements
  checks = {
    "PubNub initialization" => content.include?("new PubNub"),
    "Quiz room initialization" => content.include?("quizRoom.initialize"),
    "Chat functionality" => content.include?("sendQuizChat"),
    "Question containers" => content.scan(/id="question-\d+"/).any?,
    "Chat input" => content.include?("data-live-quiz-target=\"chatInput\""),
    "Scoreboard" => content.include?("live-quiz-scores")
  }
  
  puts "\nElement checks:"
  checks.each do |element, found|
    status = found ? "✓" : "✗"
    puts "  #{status} #{element}"
  end
  
  # Check quiz status
  status_response = URI.open("http://localhost:3000/live_quiz/till_start/2.json")
  status_data = JSON.parse(status_response.read)
  
  puts "\nQuiz status:"
  if status_data["status"]
    puts "  Status: #{status_data['status']}"
  elsif status_data["time"]
    puts "  Starting in: #{status_data['time']} seconds"
  end
  
  all_good = checks.values.all?
  
  if all_good
    puts "\n✅ ALL QUIZ COMPONENTS ARE WORKING!"
  else
    puts "\n⚠️  Some components may need attention"
  end
  
rescue => e
  puts "✗ Error accessing quiz: #{e.message}"
end

puts "\nTo fully test:"
puts "1. Open http://localhost:3000/live_quiz/2 in a browser"
puts "2. Open browser console (F12)"
puts "3. Check for any JavaScript errors"
puts "4. Wait for quiz to start and verify questions appear"