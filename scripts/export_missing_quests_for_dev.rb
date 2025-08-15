#!/usr/bin/env ruby
# Script to export missing quest data (levels 1-18) from production
# 
# Instructions:
# 1. Copy this file to your production server
# 2. Run: bundle exec rails runner export_missing_quests_for_dev.rb > missing_quests.rb
# 3. Copy the missing_quests.rb file back to development
# 4. Run in development: bundle exec rails runner missing_quests.rb

puts "# Missing quest data for levels 1-18"
puts "# Exported from production: #{Time.now}"
puts "# Database: #{Rails.env}"
puts

# Check what we're about to export
quest_count = Quest.where(level: 1..18).count
if quest_count == 0
  puts "# ERROR: No quests found for levels 1-18 in this database!"
  puts "# Make sure you're running this on the production server."
  exit 1
end

puts "# Found #{quest_count} quests for levels 1-18"
puts

# Generate the import code
puts "ActiveRecord::Base.transaction do"
puts "  # Check if quests already exist to avoid duplicates"
puts "  existing_levels = Quest.where(level: 1..18).pluck(:level).uniq"
puts "  if existing_levels.any?"
puts "    puts \"Quests already exist for levels: #{existing_levels.join(', ')}\""
puts "    puts \"Aborting to avoid duplicates.\""
puts "    raise ActiveRecord::Rollback"
puts "  end"
puts
puts "  # Create the missing quests"
puts "  quests_created = 0"
puts

Quest.where(level: 1..18).order(:level, :id).each do |quest|
  puts "  Quest.create!("
  puts "    level: #{quest.level},"
  puts "    objective: #{quest.objective.inspect},"
  puts "    qualifier: #{quest.qualifier.inspect},"
  puts "    quantity: #{quest.quantity},"
  if quest.task.present?
    puts "    task: #{quest.task.inspect},"
  end
  if quest.description.present?
    puts "    description: #{quest.description.inspect},"
  end
  if quest.url.present?
    puts "    url: #{quest.url.inspect},"
  end
  puts "    created_at: Time.current,"
  puts "    updated_at: Time.current"
  puts "  )"
  puts "  quests_created += 1"
  puts
end

puts "  puts \"Successfully created #{quests_created} quests for levels 1-18\""
puts "end"