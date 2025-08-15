# Simple quest export script for production
# Run on production: bundle exec rails runner scripts/export_quests_simple.rb > quest_data.rb

puts "# Quest data from production database"
puts "# Exported at: #{Time.now}"
puts
puts "# Missing levels 1-18 quest data for development environment"
puts

# Only export quests for levels 1-18 since those are missing in development
Quest.where(level: 1..18).order(:level, :id).each do |q|
  puts "Quest.create!("
  puts "  level: #{q.level},"
  puts "  objective: #{q.objective.inspect},"
  puts "  qualifier: #{q.qualifier.inspect},"
  puts "  quantity: #{q.quantity.inspect},"
  puts "  task: #{q.task.inspect},"
  puts "  description: #{q.description.inspect},"
  puts "  url: #{q.url.inspect}"
  puts ")"
  puts
end

puts "# Total quests for levels 1-18: #{Quest.where(level: 1..18).count}"