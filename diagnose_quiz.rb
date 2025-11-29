#!/usr/bin/env ruby
require 'time'
require 'ice_cube'
require 'fugit'

puts "Quiz Timing Diagnosis Report"
puts "=" * 60

# Current time info
current_utc = Time.now.utc
current_pst = Time.now.getlocal('-08:00')
puts "\nCurrent Times:"
puts "  UTC: #{current_utc}"
puts "  PST: #{current_pst}"

# Check DST
puts "\nDaylight Saving Time Check:"
puts "  Is PST currently in DST? #{current_pst.dst?}"

# IceCube Schedule Analysis
puts "\n\nIceCube Schedule Analysis:"
puts "-" * 40
schedule = IceCube::Schedule.new(current_utc)
schedule.add_recurrence_rule(IceCube::Rule.weekly.day(:tuesday).hour_of_day(17).minute_of_hour(0).second_of_minute(0))
schedule.add_recurrence_rule(IceCube::Rule.weekly.day(:saturday).hour_of_day(23).minute_of_hour(0).second_of_minute(0))

puts "Next 5 occurrences:"
schedule.next_occurrences(5).each do |occ|
  pst_time = occ.getlocal('-08:00')
  puts "  #{occ} UTC => #{pst_time} PST"
end

# Fugit Cron Analysis
puts "\n\nFugit Cron Analysis:"
puts "-" * 40
tuesday_cron = Fugit::Cron.parse("0 17 * * 2")
saturday_cron = Fugit::Cron.parse("0 23 * * 6")

puts "Tuesday schedule (0 17 * * 2):"
tuesday_next = tuesday_cron.next_time(current_utc)
tuesday_next_time = tuesday_next.to_time
puts "  Next: #{tuesday_next_time} UTC => #{tuesday_next_time.getlocal('-08:00')} PST"

puts "\nSaturday schedule (0 23 * * 6):"
saturday_next = saturday_cron.next_time(current_utc)
saturday_next_time = saturday_next.to_time
puts "  Next: #{saturday_next_time} UTC => #{saturday_next_time.getlocal('-08:00')} PST"

# JavaScript Date Simulation
puts "\n\nJavaScript Date Simulation:"
puts "-" * 40
puts "For schedule times:"
[["Tuesday", 17, 0], ["Saturday", 23, 0]].each do |day, hour, minute|
  # Simulate what JavaScript would do
  test_date = Time.utc(current_utc.year, current_utc.month, current_utc.day, hour, minute, 0)
  local_str = test_date.getlocal('-08:00').strftime("%l:%M %p %Z").strip
  puts "  #{day} at #{hour}:#{minute.to_s.rjust(2, '0')} UTC => #{local_str}"
end

# Expected vs Actual Analysis
puts "\n\nExpected Schedule (PST/PDT):"
puts "-" * 40
puts "Tuesday: 9:00 AM PST/10:00 AM PDT"
puts "Saturday: 3:00 PM PST/4:00 PM PDT"
puts "\nCurrent timezone offset: #{current_pst.strftime('%z')} (#{current_pst.zone})"

# Recommendation
puts "\n\nAnalysis:"
puts "-" * 40
if current_pst.dst?
  puts "WARNING: Currently in Daylight Saving Time (PDT)"
  puts "Quiz times will appear 1 hour later than standard time"
else
  puts "Currently in Standard Time (PST)"
  puts "Quiz times should appear at the expected times"
end