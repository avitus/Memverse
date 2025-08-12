#!/usr/bin/env ruby
# Script to extract missing quest data from production database
# Run this on production server and copy output to development

require_relative '../config/environment'

puts "# Quest data extraction script"
puts "# Generated on: #{Time.now}"
puts "# " + "=" * 60
puts

# Check which levels have quests
all_quest_levels = Quest.pluck(:level).uniq.sort
puts "# Quest levels found in database: #{all_quest_levels.inspect}"
puts "# Total levels with quests: #{all_quest_levels.count}"
puts

# Identify missing levels (1-18)
missing_levels = (1..18).to_a - all_quest_levels
if missing_levels.any?
  puts "# WARNING: Missing quest levels: #{missing_levels.inspect}"
else
  puts "# All levels 1-18 have quests defined"
end
puts

# Generate Ruby code to recreate all quests
puts "# Ruby code to recreate quests:"
puts "# Copy this into db/seeds.rb or a migration"
puts
puts "# Clear existing quests if needed (uncomment to use):"
puts "# Quest.destroy_all"
puts
puts "# Create quests for all levels:"
puts "quest_data = ["

# Extract all quests ordered by level and id
Quest.order(:level, :id).each do |quest|
  attributes = {
    level: quest.level,
    objective: quest.objective,
    qualifier: quest.qualifier,
    quantity: quest.quantity,
    task: quest.task,
    description: quest.description,
    url: quest.url
  }
  
  # Remove nil values to keep output clean
  attributes.compact!
  
  puts "  #{attributes.inspect},"
end

puts "]"
puts
puts "quest_data.each do |data|"
puts "  Quest.create!(data)"
puts "end"
puts
puts "puts \"Created #{quest_data.length} quests\""

# Also generate a SQL dump format
puts
puts "# " + "=" * 60
puts "# SQL format (alternative):"
puts "# " + "=" * 60
puts

Quest.order(:level, :id).each do |quest|
  values = [
    quest.level,
    quest.objective ? "'#{quest.objective.gsub("'", "''")}'" : "NULL",
    quest.qualifier ? "'#{quest.qualifier.gsub("'", "''")}'" : "NULL", 
    quest.quantity || "NULL",
    quest.task ? "'#{quest.task.gsub("'", "''")}'" : "NULL",
    quest.description ? "'#{quest.description.gsub("'", "''")}'" : "NULL",
    quest.url ? "'#{quest.url.gsub("'", "''")}'" : "NULL"
  ].join(", ")
  
  puts "INSERT INTO quests (level, objective, qualifier, quantity, task, description, url, created_at, updated_at) VALUES (#{values}, NOW(), NOW());"
end

# Summary statistics
puts
puts "# " + "=" * 60
puts "# Summary:"
puts "# " + "=" * 60
level_counts = Quest.group(:level).count.sort
level_counts.each do |level, count|
  puts "# Level #{level}: #{count} quests"
end
puts "# Total quests: #{Quest.count}"