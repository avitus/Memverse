# Template migration file for adding missing quests
# 
# To use this:
# 1. Run on production: bundle exec rails runner scripts/export_quests_simple.rb > tmp/quest_data.rb
# 2. Copy the quest_data.rb file to your development machine
# 3. Create a migration: bundle exec rails generate migration AddMissingQuests
# 4. Replace the migration content with this template
# 5. Insert the quest data from quest_data.rb into the `quest_data` array below

class AddMissingQuests < ActiveRecord::Migration[7.0]
  def up
    # Check if we already have quests for levels 1-18
    existing_levels = Quest.where(level: 1..18).pluck(:level).uniq
    
    if existing_levels.any?
      puts "Quests already exist for levels: #{existing_levels.join(', ')}"
      puts "Skipping quest creation to avoid duplicates"
      return
    end
    
    # Quest data array - INSERT PRODUCTION DATA HERE
    quest_data = [
      # Example format:
      # { level: 1, objective: "Verses", qualifier: "Learning", quantity: 5, task: "Add 5 verses", description: "Add 5 verses to start learning" },
      # { level: 1, objective: "Verses", qualifier: "Memorized", quantity: 1, task: "Memorize 1 verse", description: "Memorize your first verse" },
      # ... paste all quest data here ...
    ]
    
    # Create quests
    quest_data.each do |data|
      Quest.create!(data)
    end
    
    puts "Created #{quest_data.length} quests for levels 1-18"
  end
  
  def down
    # Remove quests for levels 1-18
    Quest.where(level: 1..18).destroy_all
  end
end