# Rails console export script
# Instructions:
# 1. SSH to production server
# 2. Run: RAILS_ENV=production bundle exec rails console
# 3. Copy and paste this code into the console
# 4. Copy the output to a file locally

puts "# Quest data for levels 1-18"
puts "# Run this in development: bundle exec rails runner quest_import.rb"
puts

Quest.where(level: 1..18).order(:level, :id).each do |q|
  attrs = []
  attrs << "level: #{q.level}"
  attrs << "objective: #{q.objective.inspect}" if q.objective
  attrs << "qualifier: #{q.qualifier.inspect}" if q.qualifier
  attrs << "quantity: #{q.quantity}" if q.quantity
  attrs << "task: #{q.task.inspect}" if q.task
  attrs << "description: #{q.description.inspect}" if q.description
  attrs << "url: #{q.url.inspect}" if q.url
  
  puts "Quest.create!(#{attrs.join(', ')})"
end

puts
puts "# Total: #{Quest.where(level: 1..18).count} quests"