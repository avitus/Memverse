# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
puts 'SETTING UP DEFAULT USER LOGIN'
user = User.create! :name => 'First User', :email => 'user@test.com', :password => 'please', :password_confirmation => 'please'
puts 'New user created: ' << user.name

# TODO: Add popular verses

# Add 50 quest levels
puts 'SETTING UP QUESTS'
for i in 10..50
  learning_verses   = (i-6)*25 + 50
  memorized_verses  = learning_verses - 50
  
  gospel_learning   = (learning_verses.to_f / 10.0).round
  epistle_learning  = (learning_verses.to_f / 10.0).round
  wisdom_learning   = (learning_verses.to_f / 20.0).round
  history_learning  = (learning_verses.to_f / 20.0).round
  prophecy_learning = (learning_verses.to_f / 20.0).round

  gospel_memorized   = (memorized_verses.to_f / 10.0).round
  epistle_memorized  = (memorized_verses.to_f / 10.0).round
  wisdom_memorized   = (memorized_verses.to_f / 20.0).round
  history_memorized  = (memorized_verses.to_f / 20.0).round
  prophecy_memorized = (memorized_verses.to_f / 20.0).round
  
  accuracy           = i + 15
  ref_recall         = [i + 50, 90].min
  
  referrals          = ((i-6).to_f / 3.0).round
  tags               = (learning_verses.to_f / 5.0).round
  
  chapters_learning  = ((i-5).to_f / 3.0).round
  chapters_memorized = ((i-7).to_f / 3.0).round

  # Learning quests
  q = Quest.where(:level => i, :objective => 'Verses', :qualifier => 'Learning')
  if !q
    Quest.create(:level => i, :objective => 'Verses', :qualifier => 'Learning', :quantity => learning_verses, :description => 'Learn #{learning_verses} verses')
  end
  
  
end
