begin
  require 'database_cleaner'
  require 'database_cleaner/cucumber'

  DatabaseCleaner.strategy = :truncation
  #https://github.com/DatabaseCleaner/database_cleaner/issues/445
  DatabaseCleaner.clean_with :truncation, except: %w(ar_internal_metadata)
  
rescue NameError
  raise "You need to add database_cleaner to your Gemfile (in the :test group) if you wish to use it."
end

Before do

  DatabaseCleaner.start

  # ----------------------------------------------------------------------------------------------------------
  # Create Final Verse data table. Probably not necessary to load Final Verse data for every chapter
  # ----------------------------------------------------------------------------------------------------------
  config = ActiveRecord::Base.configurations[Rails.env]
  if config['adapter'] == 'mysql2'
    system("mysql --user=#{config['username']} --password=#{config['password']} --host=#{config['host']} #{config['database']} < iso_final_verses.sql")
  elsif config['adapter'] == 'sqlite3'
    system("sqlite3 #{config['database']} < iso_final_verses.sql")
  else
    puts "WARNING: FinalVerse data could not be seeded for #{config['adapter']}. Please see db/seeds.rb."
  end

end

Before('@badges') do

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
    Quest.create(:badge_id => sotm.id, :objective => 'Chapters', :qualifier => 'Matthew 5', :task => "Memorize Matthew 5")
  end
  q = Quest.where(:level => nil, :objective => 'Chapters', :qualifier => 'Matthew 6').first
  if !q
    puts '      - Added Matthew 6 quest'
    Quest.create(:badge_id => sotm.id, :objective => 'Chapters', :qualifier => 'Matthew 6', :task => "Memorize Matthew 6")
  end
  q = Quest.where(:level => nil, :objective => 'Chapters', :qualifier => 'Matthew 7').first
  if !q
    puts '      - Added Matthew 7 quest'
    Quest.create(:badge_id => sotm.id, :objective => 'Chapters', :qualifier => 'Matthew 7', :task => "Memorize Matthew 7")
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

end

After do |scenario|
  DatabaseCleaner.clean
end

