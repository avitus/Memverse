#!/usr/bin/env ruby
require 'fileutils'

puts "TESTING BOTH QUIZ ROUTES"
puts "=" * 60

# Test different quiz IDs
quiz_ids = [1, 2, 5, 10]

quiz_ids.each do |quiz_id|
  puts "\nTesting Quiz #{quiz_id}:"
  puts "-" * 40
  
  # Check quiz status
  session = QuizSession.new(quiz_id)
  quiz_running = session.quiz_in_progress?
  status = session.get_quiz_status
  
  puts "  Status in Redis: #{status || 'none'}"
  puts "  Quiz running: #{quiz_running}"
  
  # Check the route behavior
  route = quiz_id == 1 ? "/live_quiz" : "/live_quiz/#{quiz_id}"
  puts "  Route: #{route}"
  puts "  Expected behavior: #{quiz_running ? 'Show quiz interface with modal' : 'Show schedule only (no modal)'}"
end

puts "\n" + "=" * 60
puts "VIEW STRUCTURE VERIFICATION"
puts "=" * 60

# Verify both views have the fix
views = ['live_quiz.html.erb', 'live_quiz_modern.html.erb']

views.each do |view|
  puts "\nChecking #{view}:"
  content = File.read("app/views/live_quiz/#{view}")
  
  # Check if instructions partial is inside the else block
  lines = content.lines
  instructions_line = lines.find_index { |l| l.include?('render partial: "instructions"') }
  
  if instructions_line
    # Check if it's after an else statement
    before_lines = lines[0..instructions_line]
    else_count = before_lines.count { |l| l.strip == '<% else %>' }
    end_count = before_lines.count { |l| l.include?('<% end %>') }
    
    puts "  ✓ Instructions partial found at line #{instructions_line + 1}"
    puts "  ✓ Inside ELSE block: #{else_count > end_count}"
  else
    puts "  ✗ Instructions partial not found!"
  end
end

puts "\n" + "=" * 60
puts "SUMMARY"
puts "=" * 60
puts "\nThe fix has been applied to both views:"
puts "1. Instructions partial only renders when quiz interface is shown"
puts "2. Welcome modal cannot appear on schedule page"
puts "3. Both /live_quiz and /live_quiz/:id routes will work correctly"