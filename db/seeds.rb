# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
# puts 'SETTING UP DEFAULT USER LOGIN'
# user = User.create :name => 'First User', :email => 'user@test.com', :password => 'please', :password_confirmation => 'please'
# puts '  New user created: ' << user.name

# TODO: Add popular verses

puts 'Seeding database'

# TODO Add countries, states etc.

# Add 50 quest levels
puts 'SETTING UP QUESTS'
for i in 19..50
  
  puts "  Creating quests for level #{i}"
  
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
  if q.empty?
    Quest.create(:level => i, :objective => 'Verses', :qualifier => 'Learning', :quantity => learning_verses, :task => "Learn #{learning_verses} verses.")
  end
  
  # Memorized quests
  q = Quest.where(:level => i, :objective => 'Verses', :qualifier => 'Memorized')
  if q.empty?
    Quest.create(:level => i, :objective => 'Verses', :qualifier => 'Memorized', :quantity => memorized_verses, :task => "Memorize #{memorized_verses} verses.")
  end  
  
  # Gospel quests
  q = Quest.where(:level => i, :objective => 'Gospels', :qualifier => 'Learning')
  if q.empty?
    Quest.create(:level => i, :objective => 'Gospels', :qualifier => 'Learning', :quantity => gospel_learning, :task => "Learn #{gospel_learning} verses from the gospels.")
  end  

  q = Quest.where(:level => i, :objective => 'Gospels', :qualifier => 'Memorized')
  if q.empty?
    Quest.create(:level => i, :objective => 'Gospels', :qualifier => 'Memorized', :quantity => gospel_memorized, :task => "Memorize #{gospel_memorized} verses from the gospels.")
  end  

  # Epistle quests
  q = Quest.where(:level => i, :objective => 'Epistles', :qualifier => 'Learning')
  if q.empty?
    Quest.create(:level => i, :objective => 'Epistles', :qualifier => 'Learning', :quantity => epistle_learning, :task => "Learn #{epistle_learning} verses from the epistles.")
  end  

  q = Quest.where(:level => i, :objective => 'Epistles', :qualifier => 'Memorized')
  if q.empty?
    Quest.create(:level => i, :objective => 'Epistles', :qualifier => 'Memorized', :quantity => epistle_memorized, :task => "Memorize #{epistle_memorized} verses from the epistles.")
  end  
  
  # Wisdom quests
  q = Quest.where(:level => i, :objective => 'Wisdom', :qualifier => 'Learning')
  if q.empty?
    Quest.create(:level => i, :objective => 'Wisdom', :qualifier => 'Learning', :quantity => wisdom_learning, :task => "Learn #{wisdom_learning} verses from the wisdom literature.")
  end  

  q = Quest.where(:level => i, :objective => 'Wisdom', :qualifier => 'Memorized')
  if q.empty?
    Quest.create(:level => i, :objective => 'Wisdom', :qualifier => 'Memorized', :quantity => wisdom_memorized, :task => "Memorize #{wisdom_memorized} verses from the wisdom literature.")
  end  
  
  # History quests
  q = Quest.where(:level => i, :objective => 'History', :qualifier => 'Learning')
  if q.empty?
    Quest.create(:level => i, :objective => 'History', :qualifier => 'Learning', :quantity => history_learning, :task => "Learn #{history_learning} verses of biblical history.")
  end  

  q = Quest.where(:level => i, :objective => 'History', :qualifier => 'Memorized')
  if q.empty?
    Quest.create(:level => i, :objective => 'History', :qualifier => 'Memorized', :quantity => history_memorized, :task => "Memorize #{history_memorized} verses of biblical history.")
  end  
  
  # Prophecy quests
  q = Quest.where(:level => i, :objective => 'Prophecy', :qualifier => 'Learning')
  if q.empty?
    Quest.create(:level => i, :objective => 'Prophecy', :qualifier => 'Learning', :quantity => prophecy_learning, :task => "Learn #{prophecy_learning} verses of biblical prophecy.")
  end  

  q = Quest.where(:level => i, :objective => 'Prophecy', :qualifier => 'Memorized')
  if q.empty?
    Quest.create(:level => i, :objective => 'Prophecy', :qualifier => 'Memorized', :quantity => prophecy_memorized, :task => "Memorize #{prophecy_memorized} verses of biblical prophecy.")
  end
  
  # Reference recall       
  q = Quest.where(:level => i, :objective => 'References')
  if q.empty?
    Quest.create(:level => i, :objective => 'References', :quantity => ref_recall, :task => "Recall #{ref_recall}% of your references.")
  end  
  
  # Accuracy test       
  q = Quest.where(:level => i, :objective => 'Accuracy')
  if q.empty?
    Quest.create(:level => i, :objective => 'Accuracy', :quantity => accuracy, :task => "Increase your accuracy test score to #{accuracy}%.")
  end    
  
  # Tags       
  q = Quest.where(:level => i, :objective => 'Tags')
  if q.empty?
    Quest.create(:level => i, :objective => 'Tags', :quantity => tags, :task => "Tag #{tags} of your memory verses.")
  end   
  
  # Referrals       
  q = Quest.where(:level => i, :objective => 'Referrals')
  if q.empty?
    Quest.create(:level => i, :objective => 'Referrals', :quantity => referrals, :task => "Refer #{referrals} active users to Memverse", :description => "To count, referred users must be active. Remember that people they refer also count toward your score.")
  end 
  
  # Chapter quests
  q = Quest.where(:level => i, :objective => 'Chapters', :qualifier => 'Learning')
  if q.empty?
    Quest.create(:level => i, :objective => 'Chapters', :qualifier => 'Learning', :quantity => chapters_learning, :task => "Learn #{chapters_learning} complete chapters.")
  end
  
  q = Quest.where(:level => i, :objective => 'Chapters', :qualifier => 'Memorized')
  if q.empty?
    Quest.create(:level => i, :objective => 'Chapters', :qualifier => 'Memorized', :quantity => chapters_memorized, :task => "Memorize #{chapters_memorized} complete chapters.")
  end    
end

# ----------------------------------------------------------------------------------------------------------   
# Create Badges
# ---------------------------------------------------------------------------------------------------------- 
puts 'CREATING BADGES'

# ---- Sermon on the Mount Badge ------------------
sotm = Badge.where(:name => 'Sermon on the Mount').first
if !sotm
  puts ' - Creating Sermon on the Mount Badge'
  sotm = Badge.create(:name => 'Sermon on the Mount', :color => 'solo', :description => "Memorize Jesus' entire Sermon on the Mount (Matthew 5-7)")
end

puts '   - Confirming three quests for Sermon on the Mount Badge (Matthew 5-7)'
q = Quest.where(:level => nil, :objective => 'Chapters', :qualifier => 'Matthew 5').first
if !q
  puts '      - Added Matthew 5 quest'
  Quest.create(:badge_id => sotm, :objective => 'Chapters', :qualifier => 'Matthew 5', :task => "Memorize Matthew 5")
end  
q = Quest.where(:level => nil, :objective => 'Chapters', :qualifier => 'Matthew 6').first
if !q
  puts '      - Added Matthew 6 quest'
  Quest.create(:badge_id => sotm, :objective => 'Chapters', :qualifier => 'Matthew 6', :task => "Memorize Matthew 6")
end  
q = Quest.where(:level => nil, :objective => 'Chapters', :qualifier => 'Matthew 7').first
if !q
  puts '      - Added Matthew 7 quest'
  Quest.create(:badge_id => sotm, :objective => 'Chapters', :qualifier => 'Matthew 7', :task => "Memorize Matthew 7")
end    

# ---- Referrer Medals ----------------------------
referrer_gold = Badge.where(:name => 'Referrer', :color => 'gold').first
if !referrer_gold
  puts ' - Creating Referrer Gold Medal'
  referrer_gold = Badge.create(:name => 'Referrer', :color => 'gold',     :description => "Refer 200 Active Users")
end

referrer_silver = Badge.where(:name => 'Referrer', :color => 'silver').first
if !referrer_silver
  puts ' - Creating Referrer Silver Medal'
  referrer_silver = Badge.create(:name => 'Referrer', :color => 'silver', :description => "Refer 100 Active Users")
end

referrer_bronze = Badge.where(:name => 'Referrer', :color => 'bronze').first
if !referrer_bronze
  puts ' - Creating Referrer Bronze Medal'
  referrer_bronze = Badge.create(:name => 'Referrer', :color => 'bronze', :description => "Refer 50 Active Users")
end

puts '   - Adding Referrer Quests'
q = Quest.where(:level => nil, :objective => 'Referrals', :quantity => 200).first
if !q
  puts '      - Referrer gold medal quests'
  referrer_gold = Badge.where(:name => 'Referrer', :color => 'gold').first
  Quest.create(:badge_id => referrer_gold.id, :objective => 'Referrals',   :quantity => 200, :task => "Refer 200 Active Users")
end  
q = Quest.where(:level => nil, :objective => 'Referrals', :quantity => 100).first
if !q
  puts '      - Referrer silver medal quests'
  referrer_silver = Badge.where(:name => 'Referrer', :color => 'silver').first
  Quest.create(:badge_id => referrer_silver.id, :objective => 'Referrals', :quantity => 100, :task => "Refer 100 Active Users")
end  
q = Quest.where(:level => nil, :objective => 'Referrals', :quantity =>  50).first
if !q
  puts '      - Referrer bronze medal quests'
  referrer_bronze = Badge.where(:name => 'Referrer', :color => 'bronze').first  
  Quest.create(:badge_id => referrer_bronze.id, :objective => 'Referrals', :quantity =>  50, :task => "Refer  50 Active Users")
end  

# ---- Consistency Medals ----------------------------
consistency_gold = Badge.where(:name => 'Consistency', :color => 'gold').first
if !consistency_gold
  puts ' - Creating Consistency Gold Medal'
  consistency_gold = Badge.create(:name => 'Consistency', :color => 'gold',     :description => "Complete 350 sessions in a year")
end

consistency_silver = Badge.where(:name => 'Consistency', :color => 'silver').first
if !consistency_silver
  puts ' - Creating Consistency Silver Medal'
  consistency_silver = Badge.create(:name => 'Consistency', :color => 'silver', :description => "Complete 325 sessions in a year")
end

consistency_bronze = Badge.where(:name => 'Consistency', :color => 'bronze').first
if !consistency_bronze
  puts ' - Creating Consistency Bronze Medal'
  consistency_bronze = Badge.create(:name => 'Consistency', :color => 'bronze', :description => "Complete 300 sessions in a year")
end

puts '   - Adding Consistency Quests'
q = Quest.where(:level => nil, :objective => 'Annual Sessions', :quantity => 350).first
if !q
  puts '      - Consistency gold medal quests'
  consistency_gold = Badge.where(:name => 'Consistency', :color => 'gold').first
  Quest.create(:badge_id => consistency_gold.id, :objective => 'Annual Sessions',   :quantity => 350, :task => "Complete 350 sessions in a year")
end  
q = Quest.where(:level => nil, :objective => 'Annual Sessions', :quantity => 325).first
if !q
  puts '      - Consistency silver medal quests'
  consistency_silver = Badge.where(:name => 'Consistency', :color => 'silver').first
  Quest.create(:badge_id => consistency_silver.id, :objective => 'Annual Sessions', :quantity => 325, :task => "Complete 325 sessions in a year")
end  
q = Quest.where(:level => nil, :objective => 'Annual Sessions', :quantity =>  300).first
if !q
  puts '      - Consistency bronze medal quests'
  consistency_bronze = Badge.where(:name => 'Consistency', :color => 'bronze').first  
  Quest.create(:badge_id => consistency_bronze.id, :objective => 'Annual Sessions', :quantity => 300, :task => "Complete 300 sessions in a year")
end  

# ----------------------------------------------------------------------------------------------------------   
# Create Final Verse data table
# ---------------------------------------------------------------------------------------------------------- 
puts "Adding final verse data"
config = ActiveRecord::Base.configurations['test']  # Change this to 'development' if seeding a new database TODO: would be nice to have working for either case
if config['adapter'] == 'mysql2'
  system("mysql --user=#{config['username']} --password=#{config['password']} #{config['database']} < iso_final_verses.sql")
elsif config['adapter'] == 'sqlite3'
  system("sqlite3 #{config['database']} < iso_final_verses.sql")
else
  puts "WARNING: FinalVerse data could not be seeded for #{config['adapter']}. Please see db/seeds.rb."
end

# ----------------------------------------------------------------------------------------------------------   
# Seed some initial verses
# ALV: Seeding the database with real verses currently breaks a lot of the Rspec tests.
# ---------------------------------------------------------------------------------------------------------- 
# puts "Adding seed verses"
# config = ActiveRecord::Base.configurations['test']  # Change this to 'development' if seeding a new database TODO: would be nice to have working for either case
# if config['adapter'] == 'mysql2'
  # system("mysql --user=#{config['username']} --password=#{config['password']} #{config['database']} < seed_verses.sql")
# elsif config['adapter'] == 'sqlite3'
  # system("sqlite3 #{config['database']} < seed_verses.sql")
# else
  # puts "WARNING: FinalVerse data could not be seeded for #{config['adapter']}. Please see db/seeds.rb."
# end

# This is the current verse seed data
# +----+-------------+------------+--------------+---------+----------+-----------------------+-----------------------+------------------------+----------+------------+--------------+------------+-----------------+
# | id | translation | book_index | book         | chapter | versenum | text                  | created_at            | updated_at             | verified | error_flag | uberverse_id | checked_by | memverses_count |
# +----+-------------+------------+--------------+---------+----------+-----------------------+-----------------------+------------------------+----------+------------+--------------+------------+-----------------+
# | 1  | NIV         | 1          | Genesis      | 1       | 1        | In the beginning G... | 2011-01-21 23:07:0... | 2011-10-24 03:47:47... | false    | false      |              |            | 3               |
# | 2  | NIV         | 1          | Genesis      | 1       | 2        | Now the earth was ... | 2011-01-21 23:08:3... | 2011-10-24 04:00:00... | false    | false      |              |            | 3               |
# | 3  | NIV         | 45         | Romans       | 8       | 1        | Therefore, there i... | 2011-01-21 23:10:1... | 2012-03-18 20:46:03... | false    | false      |              |            | 2               |
# | 4  | NIV         | 45         | Romans       | 8       | 2        | because through Ch... | 2011-01-21 23:10:3... | 2012-03-18 20:46:05... | false    | false      |              |            | 2               |
# | 5  | NIV         | 45         | Romans       | 8       | 3        | For what the law w... | 2011-01-21 23:10:4... | 2012-03-18 20:46:06... | false    | false      |              |            | 2               |
# | 6  | NIV         | 49         | Ephesians    | 1       | 3        | Praise be to the G... | 2011-01-27 23:28:2... | 2011-10-24 03:52:29... | true     | true       |              | avitus     | 3               |
# | 7  | NIV         | 49         | Ephesians    | 1       | 4        | For he chose us in... | 2011-01-27 23:28:3... | 2012-03-20 18:10:58... | true     | true       |              |            | 2               |
# | 8  | NIV         | 49         | Ephesians    | 1       | 5        | he predestined us ... | 2011-01-27 23:35:2... | 2011-06-24 03:18:28... | false    | false      |              |            | 1               |
# | 9  | TMB         | 44         | Acts         | 1       | 2        | sampai pada hari I... | 2011-02-01 00:09:1... | 2011-06-24 03:18:28... | false    | false      |              |            | 1               |
# | 10 | NIV         | 44         | Acts         | 1       | 2        | until the day he w... | 2011-02-03 22:13:0... | 2012-03-20 18:30:30... | true     | false      |              |            | 2               |
# | 11 | NIV         | 19         | Psalms       | 1       | 1        | Blessed is the man... | 2011-02-10 00:39:2... | 2012-03-18 19:36:21... | false    | false      |              |            | 2               |
# | 12 | NIV         | 19         | Psalms       | 1       | 2        | But his delight is... | 2011-02-10 00:45:5... | 2012-03-18 19:36:21... | false    | false      |              |            | 2               |
# | 13 | NIV         | 19         | Psalms       | 1       | 3        | He is like a tree ... | 2011-02-10 00:46:2... | 2012-03-18 19:36:21... | false    | false      |              |            | 2               |
# | 14 | NIV         | 19         | Psalms       | 1       | 4        | Not so the wicked!... | 2011-02-10 00:46:5... | 2012-03-18 19:36:21... | false    | false      |              |            | 2               |
# | 15 | NIV         | 19         | Psalms       | 1       | 5        | Therefore the wick... | 2011-02-10 00:47:1... | 2012-03-18 19:36:21... | false    | false      |              |            | 2               |
# | 16 | NIV         | 19         | Psalms       | 1       | 6        | For the LORD watch... | 2011-02-10 00:47:3... | 2012-03-18 19:36:21... | false    | false      |              |            | 2               |
# | 17 | NIV         | 45         | Romans       | 8       | 4        | in order that the ... | 2011-02-12 00:02:0... | 2011-06-24 03:18:28... | false    | false      |              |            | 1               |
# | 18 | NIV         | 45         | Romans       | 8       | 5        | Those who live acc... | 2011-02-12 00:07:1... | 2011-06-24 03:18:28... | false    | false      |              |            | 1               |
# | 19 | NIV         | 45         | Romans       | 8       | 6        | The mind of sinful... | 2011-02-12 00:12:1... | 2011-02-12 00:12:16... | false    | false      |              |            | 0               |
# | 20 | NIV         | 45         | Romans       | 8       | 7        | the sinful mind is... | 2011-02-12 00:20:1... | 2011-06-24 03:18:28... | false    | false      |              |            | 1               |
# | 21 | NIV         | 45         | Romans       | 8       | 8        | Those controlled b... | 2011-02-12 00:32:1... | 2011-06-24 03:18:28... | false    | false      |              |            | 1               |
# | 22 | NIV         | 45         | Romans       | 8       | 9        | You, however, are ... | 2011-02-12 00:54:0... | 2012-02-16 05:05:20... | false    | false      |              |            | 2               |
# | 23 | NIV         | 45         | Romans       | 8       | 10       | But if Christ is i... | 2011-02-12 01:04:1... | 2012-02-16 05:05:24... | false    | false      |              |            | 3               |
# | 24 | NIV         | 45         | Romans       | 8       | 11       | And if the Spirit ... | 2011-02-12 01:06:4... | 2012-02-16 05:05:28... | false    | false      |              |            | 2               |
# | 25 | NIV         | 45         | Romans       | 8       | 12       | Therefore, brother... | 2011-02-12 01:17:5... | 2012-02-16 05:05:31... | false    | false      |              |            | 2               |
# | 26 | NIV         | 64         | 3 John       | 1       | 1        | The elder, To my d... | 2011-02-18 23:20:0... | 2011-06-24 03:18:28... | false    | false      |              |            | 1               |
# | 27 | NIV         | 64         | 3 John       | 1       | 2        | Dear friend, I pra... | 2011-02-18 23:20:2... | 2011-06-24 03:18:28... | false    | false      |              |            | 1               |
# | 28 | NIV         | 64         | 3 John       | 1       | 3        | It gave me great j... | 2011-02-18 23:20:4... | 2011-06-24 03:18:28... | false    | false      |              |            | 1               |
# | 29 | NIV         | 64         | 3 John       | 1       | 4        | I have no greater ... | 2011-02-18 23:20:5... | 2011-06-24 03:18:28... | false    | false      |              |            | 1               |
# | 30 | NIV         | 64         | 3 John       | 1       | 5        | Dear friend, you a... | 2011-02-18 23:21:2... | 2011-06-24 03:18:28... | false    | false      |              |            | 1               |
# | 31 | NIV         | 64         | 3 John       | 1       | 6        | They have told the... | 2011-02-18 23:21:3... | 2011-06-24 03:18:28... | false    | false      |              |            | 1               |
# | 32 | NIV         | 64         | 3 John       | 1       | 7        | It was for the sak... | 2011-02-18 23:21:5... | 2011-06-24 03:18:29... | false    | false      |              |            | 1               |
# | 33 | NIV         | 64         | 3 John       | 1       | 8        | We ought therefore... | 2011-02-18 23:22:1... | 2011-06-24 03:18:29... | false    | false      |              |            | 1               |
# | 34 | NIV         | 64         | 3 John       | 1       | 9        | I wrote to the chu... | 2011-02-18 23:22:2... | 2011-06-24 03:18:29... | false    | false      |              |            | 1               |
# | 35 | NIV         | 64         | 3 John       | 1       | 10       | So if I come, I wi... | 2011-02-18 23:22:4... | 2011-06-24 03:18:29... | false    | false      |              |            | 1               |
# | 36 | NIV         | 64         | 3 John       | 1       | 11       | Dear friend, do no... | 2011-02-18 23:22:5... | 2011-06-24 03:18:29... | false    | false      |              |            | 1               |
# | 37 | NIV         | 64         | 3 John       | 1       | 12       | Demetrius is well ... | 2011-02-18 23:23:1... | 2011-06-24 03:18:29... | false    | false      |              |            | 2               |
# | 38 | NIV         | 64         | 3 John       | 1       | 13       | I have much to wri... | 2011-02-18 23:23:3... | 2011-06-24 03:18:29... | false    | false      |              |            | 1               |
# | 39 | NIV         | 64         | 3 John       | 1       | 14       | I hope to see you ... | 2011-02-18 23:24:0... | 2011-06-24 03:18:29... | false    | false      |              |            | 1               |
# | 40 | NIV         | 19         | Psalms       | 98      | 1        | Sing to the LORD a... | 2011-03-21 03:53:5... | 2012-03-15 04:06:22... | false    | false      |              |            | 1               |
# | 41 | NIV         | 19         | Psalms       | 98      | 2        | The LORD has made ... | 2011-03-21 03:56:3... | 2012-03-15 04:06:22... | false    | false      |              |            | 1               |
# | 42 | NIV         | 33         | Micah        | 6       | 8        | He has showed you,... | 2011-03-26 18:49:0... | 2011-06-24 03:18:29... | false    | false      |              |            | 1               |
# | 43 | NIV         | 21         | Ecclesiastes | 3       | 11       | He has made everyt... | 2011-03-26 18:49:3... | 2011-06-24 03:18:29... | false    | false      |              |            | 1               |
# | 44 | NIV         | 66         | Revelation   | 21      | 1        | Then I saw a new h... | 2011-03-26 18:50:1... | 2011-06-24 03:18:29... | false    | false      |              |            | 1               |
# | 45 | ESV         | 51         | Colossians   | 1       | 2        | To the saints and ... | 2011-05-30 19:08:4... | 2011-06-24 03:18:29... | true     | false      |              |            | 1               |
# | 46 | ESV         | 45         | Romans       | 8       | 1        | There is therefore... | 2011-07-08 02:01:2... | 2011-07-08 02:01:28... | true     | false      |              |            | 0               |
# | 47 | ESV         | 45         | Romans       | 8       | 2        | For the law of the... | 2011-07-08 02:01:3... | 2011-07-08 02:01:39... | true     | false      |              |            | 0               |
# | 48 | ESV         | 45         | Romans       | 8       | 3        | For God has done w... | 2011-07-08 02:01:4... | 2011-07-08 02:01:47... | true     | false      |              |            | 0               |
# | 49 | NAS         | 45         | Romans       | 8       | 1        | Therefore there is... | 2011-07-08 02:02:3... | 2011-07-08 02:02:32... | false    | false      |              |            | 0               |
# | 50 | NAS         | 45         | Romans       | 8       | 2        | For the law of the... | 2011-07-08 02:02:5... | 2011-07-08 02:02:51... | false    | false      |              |            | 0               |
# | 51 | NAS         | 45         | Romans       | 8       | 3        | For what the Law c... | 2011-07-08 02:03:0... | 2011-07-08 02:03:06... | false    | false      |              |            | 0               |
# | 52 | KJV         | 45         | Romans       | 8       | 1        | There is therefore... | 2011-07-08 02:03:2... | 2011-07-08 02:03:29... | false    | false      |              |            | 0               |
# | 53 | KJV         | 45         | Romans       | 8       | 2        | For the law of the... | 2011-07-08 02:03:5... | 2011-07-08 02:03:50... | false    | false      |              |            | 0               |
# | 54 | KJV         | 45         | Romans       | 8       | 3        | For what the law c... | 2011-07-08 02:04:1... | 2011-07-08 02:04:11... | false    | false      |              |            | 0               |
# | 55 | NKJ         | 45         | Romans       | 8       | 1        | There is therefore... | 2011-07-08 02:04:4... | 2011-07-08 02:04:47... | false    | false      |              |            | 0               |
# | 56 | NKJ         | 45         | Romans       | 8       | 2        | For the law of the... | 2011-07-08 02:05:0... | 2011-07-08 02:05:05... | false    | false      |              |            | 0               |
# | 57 | NKJ         | 45         | Romans       | 8       | 3        | For what the law c... | 2011-07-08 02:05:2... | 2011-07-08 02:05:25... | false    | false      |              |            | 0               |
# | 58 | NIV         | 1          | Genesis      | 1       | 3        | And God said, “Let... | 2011-07-08 05:51:3... | 2011-07-08 05:51:36... | false    | false      |              |            | 1               |
# | 59 | NIV         | 1          | Genesis      | 1       | 4        | God saw that the l... | 2011-07-08 05:52:0... | 2011-07-08 05:52:00... | false    | false      |              |            | 1               |
# | 60 | NIV         | 1          | Genesis      | 1       | 5        | God called the lig... | 2011-07-08 05:52:2... | 2011-07-08 05:52:23... | false    | false      |              |            | 1               |
# | 61 | NIV         | 45         | Romans       | 8       | 13       | For if you live ac... | 2012-02-16 05:00:0... | 2012-02-16 05:00:00... | false    | false      |              |            | 1               |
# | 62 | NIV         | 45         | Romans       | 8       | 14       | because those who ... | 2012-02-16 05:01:0... | 2012-02-16 05:01:09... | false    | false      |              |            | 1               |
# | 63 | NIV         | 45         | Romans       | 8       | 15       | For you did not re... | 2012-02-16 05:04:5... | 2012-02-16 05:04:50... | false    | false      |              |            | 1               |
# | 64 | NIV         | 45         | Romans       | 8       | 16       | The Spirit himself... | 2012-02-18 17:10:4... | 2012-02-18 17:10:43... | false    | false      |              |            | 1               |
# | 68 | ESV         | 19         | Psalms       | 1       | 1        | Blessed is the man... | 2012-03-15 04:27:5... | 2012-03-18 19:36:01... | false    | false      |              |            | 0               |
# | 69 | ESV         | 19         | Psalms       | 1       | 2        | but his delight is... | 2012-03-15 04:28:1... | 2012-03-18 19:36:01... | false    | false      |              |            | 0               |
# | 70 | ESV         | 19         | Psalms       | 1       | 3        | He is like a tree ... | 2012-03-15 04:31:0... | 2012-03-18 19:36:01... | false    | false      |              |            | 0               |
# | 71 | ESV         | 19         | Psalms       | 1       | 4        | The wicked are not... | 2012-03-15 04:33:4... | 2012-03-18 19:36:01... | false    | false      |              |            | 0               |
# | 72 | ESV         | 19         | Psalms       | 1       | 5        | Therefore the wick... | 2012-03-15 04:33:5... | 2012-03-18 19:36:01... | false    | false      |              |            | 0               |
# | 73 | ESV         | 19         | Psalms       | 1       | 6        | for the Lord knows... | 2012-03-15 04:34:1... | 2012-03-18 19:36:01... | false    | false      |              |            | 0               |
# +----+-------------+------------+--------------+---------+----------+-----------------------+-----------------------+------------------------+----------+------------+--------------+------------+-----------------+








