# Quick check script for production console
# Run in production Rails console to verify quest data exists

puts "Checking quest levels..."
levels = Quest.pluck(:level).compact.uniq.sort
puts "Levels with quests: #{levels.inspect}"
puts "Total levels: #{levels.count}"

missing = (1..18).to_a - levels
if missing.any?
  puts "WARNING: Missing levels 1-18: #{missing.inspect}"
else
  puts "Good: All levels 1-18 have quests"
  puts "Quest count for levels 1-18: #{Quest.where(level: 1..18).count}"
end

# Show sample
puts "\nSample quests for level 1:"
Quest.where(level: 1).each do |q|
  puts "- #{q.objective} #{q.qualifier}: #{q.quantity}"
end