#!/usr/bin/env ruby
# Script to check which quest levels are missing in the current environment
# Run locally with: bundle exec rails runner scripts/check_missing_quests.rb

puts "Checking for missing quest levels..."
puts "=" * 50

# Get all levels that have quests
levels_with_quests = Quest.pluck(:level).compact.uniq.sort

puts "\nLevels with quests: #{levels_with_quests.inspect}"
puts "Total levels with quests: #{levels_with_quests.count}"

# Check for missing levels in different ranges
missing_1_to_18 = (1..18).to_a - levels_with_quests
missing_1_to_50 = (1..50).to_a - levels_with_quests

puts "\nMissing levels 1-18: #{missing_1_to_18.inspect}"
puts "Missing levels 1-50: #{missing_1_to_50.inspect}"

# Show quest count by level
puts "\nQuest count by level:"
Quest.group(:level).count.sort_by { |level, count| level || 0 }.each do |level, count|
  puts "  Level #{level}: #{count} quests"
end

# Show sample quests for existing levels
puts "\nSample quests from existing levels:"
Quest.select(:level, :objective, :qualifier, :quantity).group_by(&:level).sort.first(5).each do |level, quests|
  puts "\n  Level #{level}:"
  quests.first(2).each do |quest|
    puts "    - #{quest.objective} #{quest.qualifier}: #{quest.quantity}"
  end
end