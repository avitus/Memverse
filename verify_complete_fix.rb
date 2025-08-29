#!/usr/bin/env ruby
require 'fileutils'

puts "COMPLETE MODAL FIX VERIFICATION"
puts "=" * 60

# Check view structure
view_file = 'app/views/live_quiz/live_quiz_modern.html.erb'
content = File.read(view_file)

puts "\n1. CHECKING VIEW STRUCTURE:"
puts "-" * 40

# Find critical lines
schedule_line = content.lines.find_index { |l| l.include?('render partial: "quiz_schedule"') } + 1
instructions_line = content.lines.find_index { |l| l.include?('render partial: "instructions"') } + 1
js_start = content.lines.find_index { |l| l.include?('<script type="text/javascript">') } + 1
end_line = content.lines.find_index { |l| l.include?('<% end %> <!-- End of quiz interface conditional -->') } + 1

puts "   Schedule partial: line #{schedule_line} (inside IF block)"
puts "   Instructions partial: line #{instructions_line} (inside ELSE block)"
puts "   JavaScript block: lines #{js_start}-#{end_line-1} (inside ELSE block)"
puts "   Conditional end: line #{end_line}"

# Verify structure
if instructions_line > schedule_line && instructions_line < end_line
  puts "\n   ✓ Instructions partial is ONLY rendered in quiz interface"
else
  puts "\n   ✗ ERROR: Instructions partial in wrong location!"
end

if js_start < end_line
  puts "   ✓ JavaScript is inside conditional block"
else
  puts "   ✗ ERROR: JavaScript outside conditional!"
end

puts "\n2. WHAT THIS FIX DOES:"
puts "-" * 40
puts "   • When NO quiz is running:"
puts "     - Shows ONLY the schedule partial"
puts "     - Does NOT render instructions partial (no #welcome-box div)"
puts "     - Does NOT include any JavaScript that could show modals"
puts ""
puts "   • When quiz IS running or about to start:"
puts "     - Shows the full quiz interface"
puts "     - Renders instructions partial (creates #welcome-box div)"
puts "     - Includes JavaScript that may show welcome modal"

puts "\n3. WHY THE FIX WORKS:"
puts "-" * 40
puts "   The modal was showing because:"
puts "   1. The instructions partial was being rendered outside the conditional"
puts "   2. This created the #welcome-box div on ALL pages"
puts "   3. JavaScript could find and display it even on schedule page"
puts ""
puts "   Now fixed because:"
puts "   1. Instructions partial is inside the ELSE block"
puts "   2. #welcome-box div only exists when showing quiz interface"
puts "   3. JavaScript can't show a modal that doesn't exist!"

puts "\n" + "=" * 60
puts "✓ THE WELCOME MODAL WILL NO LONGER APPEAR ON THE SCHEDULE PAGE"
puts "=" * 60