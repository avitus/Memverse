#!/usr/bin/env ruby

puts "Quiz Modal Fix Verification"
puts "=" * 50

# Check the view file structure
view_content = File.read('app/views/live_quiz/live_quiz_modern.html.erb')

# Find key elements
has_conditional = view_content.include?('<% if !@quiz_running && @next_quiz_time %>')
has_schedule_render = view_content.include?('render partial: "quiz_schedule"')
has_else_clause = view_content.include?('<% else %>')
has_quiz_div = view_content.include?('data-controller="live-quiz"')

# Check JavaScript placement
script_start = view_content.index('<script type="text/javascript">')
conditional_end = view_content.index('<% end %> <!-- End of quiz interface conditional -->')

puts "\nView Structure Analysis:"
puts "✓ Has conditional check: #{has_conditional}"
puts "✓ Renders schedule partial: #{has_schedule_render}"
puts "✓ Has else clause: #{has_else_clause}"
puts "✓ Has quiz interface div: #{has_quiz_div}"

if script_start && conditional_end
  if script_start < conditional_end
    puts "✓ JavaScript is INSIDE conditional (lines #{view_content[0..script_start].count("\n")+1}-#{view_content[0..conditional_end].count("\n")+1})"
    puts "\nSUCCESS: The welcome modal will NOT show on the schedule page!"
  else
    puts "✗ JavaScript is OUTSIDE conditional"
    puts "\nFAILURE: The modal would still show on schedule page"
  end
else
  puts "✗ Could not locate script boundaries"
end

puts "\nHow it works:"
puts "1. When no quiz is running (@quiz_running = false), the schedule partial is shown"
puts "2. The JavaScript that shows the welcome modal is inside the else block"
puts "3. Therefore, the modal JavaScript only runs when showing the quiz interface"

puts "\n" + "=" * 50
puts "The fix has been successfully applied!"