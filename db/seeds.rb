require 'factory_girl_rails'

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

puts "====> Seeding #{Rails.env} environment"

# puts 'SETTING UP ADMIN USER'
user = User.create :name => 'Andy', :email => 'admin@test.com', :password => 'please', :password_confirmation => 'please'
user.confirm
user.admin = true
user.save
puts 'Creating admin user: ' << user.name

# TODO: Add popular verses
# TODO Add countries

puts "Seeding states"
AmericanState.create(abbrev: 'AL', name: 'Alabama')
AmericanState.create(abbrev: 'AK', name: 'Alaska')
AmericanState.create(abbrev: 'AZ', name: 'Arizona')
AmericanState.create(abbrev: 'AR', name: 'Arkansas')
AmericanState.create(abbrev: 'CA', name: 'California')
AmericanState.create(abbrev: 'CO', name: 'Colorado')
AmericanState.create(abbrev: 'CT', name: 'Connecticut')
AmericanState.create(abbrev: 'DE', name: 'Delaware')
AmericanState.create(abbrev: 'DC', name: 'District of Columbia')
AmericanState.create(abbrev: 'FL', name: 'Florida')
AmericanState.create(abbrev: 'GA', name: 'Georgia')
AmericanState.create(abbrev: 'HI', name: 'Hawaii')
AmericanState.create(abbrev: 'ID', name: 'Idaho')
AmericanState.create(abbrev: 'IL', name: 'Illinois')
AmericanState.create(abbrev: 'IN', name: 'Indiana')
AmericanState.create(abbrev: 'IA', name: 'Iowa')
AmericanState.create(abbrev: 'KS', name: 'Kansas')
AmericanState.create(abbrev: 'KY', name: 'Kentucky')
AmericanState.create(abbrev: 'LA', name: 'Louisiana')
AmericanState.create(abbrev: 'ME', name: 'Maine')
AmericanState.create(abbrev: 'MD', name: 'Maryland')
AmericanState.create(abbrev: 'MA', name: 'Massachusetts')
AmericanState.create(abbrev: 'MI', name: 'Michigan')
AmericanState.create(abbrev: 'MN', name: 'Minnesota')
AmericanState.create(abbrev: 'MS', name: 'Mississippi')
AmericanState.create(abbrev: 'MO', name: 'Missouri')
AmericanState.create(abbrev: 'MT', name: 'Montana')
AmericanState.create(abbrev: 'NE', name: 'Nebraska')
AmericanState.create(abbrev: 'NV', name: 'Nevada')
AmericanState.create(abbrev: 'NH', name: 'New Hampshire')
AmericanState.create(abbrev: 'NJ', name: 'New Jersey')
AmericanState.create(abbrev: 'NM', name: 'New Mexico')
AmericanState.create(abbrev: 'NY', name: 'New York')
AmericanState.create(abbrev: 'NC', name: 'North Carolina')
AmericanState.create(abbrev: 'ND', name: 'North Dakota')
AmericanState.create(abbrev: 'OH', name: 'Ohio')
AmericanState.create(abbrev: 'OK', name: 'Oklahoma')
AmericanState.create(abbrev: 'OR', name: 'Oregon')
AmericanState.create(abbrev: 'PA', name: 'Pennsylvania')
AmericanState.create(abbrev: 'PR', name: 'Puerto Rico')
AmericanState.create(abbrev: 'RI', name: 'Rhode Island')
AmericanState.create(abbrev: 'SC', name: 'South Carolina')
AmericanState.create(abbrev: 'SD', name: 'South Dakota')
AmericanState.create(abbrev: 'TN', name: 'Tennessee')
AmericanState.create(abbrev: 'TX', name: 'Texas')
AmericanState.create(abbrev: 'UT', name: 'Utah')
AmericanState.create(abbrev: 'VT', name: 'Vermont')
AmericanState.create(abbrev: 'VI', name: 'Virgin Islands')
AmericanState.create(abbrev: 'VA', name: 'Virginia')
AmericanState.create(abbrev: 'WA', name: 'Washington')
AmericanState.create(abbrev: 'WV', name: 'West Virginia')
AmericanState.create(abbrev: 'WI', name: 'Wisconsin')
AmericanState.create(abbrev: 'WY', name: 'Wyoming')

# Add 50 quest levels
puts 'Setting up quests'
for i in 19..50

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
# Create Roles
# ----------------------------------------------------------------------------------------------------------
puts 'Creating roles'
puts '   - admin'
Role.create(name: "admin")
puts '   - blogger'
Role.create(name: "blogger")
puts '   - quizmaster'
Role.create(name: "quizmaster")
puts '   - scribe'
Role.create(name: "scribe")
puts '   - moderator'
Role.create(name: "moderator")

puts 'Giving admin user all roles and priviliges'
admin_user = User.where(email: 'admin@test.com').first

Role.where(name: "admin"     ).first.users << admin_user
Role.where(name: "blogger"   ).first.users << admin_user
Role.where(name: "quizmaster").first.users << admin_user
Role.where(name: "scribe"    ).first.users << admin_user
Role.where(name: "moderator" ).first.users << admin_user


# ----------------------------------------------------------------------------------------------------------
# Create Blog and First Post
# ----------------------------------------------------------------------------------------------------------
puts 'Creating blog'
blog = Bloggity::Blog.new(id: 9, title: "Memverse Blog")
blog.save unless Bloggity::Blog.exists?(9)
puts '   - first post'
post = Bloggity::BlogPost.new(title: "Welcome to Memverse", 
                              body: "Thanks for joining our team of developers.",
                              blog_id: blog.id,
                              posted_by: user,
                              tag_string: "welcome",
                              is_complete: true
                              )
post.save

# ----------------------------------------------------------------------------------------------------------
# Create Badges
# ----------------------------------------------------------------------------------------------------------
puts 'Creating badges'

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

# ----------------------------------------------------------------------------------------------------------
# Create Final Verse data table
# ----------------------------------------------------------------------------------------------------------
puts "Adding final verse data (last verse of each chapter of the Bible) for #{Rails.env} environment"
config = ActiveRecord::Base.configurations[Rails.env]
puts config
if config['adapter'] == 'mysql2'
  puts "  Configuration:"
  puts "    mysql --user=#{config['username']} --password=\"#{config['password']}\" --host=#{config['host']} #{config['database']} < iso_final_verses.sql" 
  system("mysql --user=#{config['username']} --password=\"#{config['password']}\" --host=#{config['host']} #{config['database']} < iso_final_verses.sql")
elsif config['adapter'] == 'sqlite3'
  system("sqlite3 #{config['database']} < iso_final_verses.sql")
else
  puts "WARNING: FinalVerse data could not be seeded for #{config['adapter']}. Please see db/seeds.rb."
end

puts "Created #{FinalVerse.count} entries"

# ----------------------------------------------------------------------------------------------------------
# Seed some initial verses
# ALV: Seeding the database with real verses currently breaks a lot of the Rspec tests.
# ----------------------------------------------------------------------------------------------------------
puts "Adding seed verses for #{Rails.env} environment"
config = ActiveRecord::Base.configurations[Rails.env]
if config['adapter'] == 'mysql2'
  puts "  ... Using MySQL database"
  system("mysql --user=#{config['username']} --password=\"#{config['password']}\" --host=#{config['host']} #{config['database']} < seed_verses.sql")
elsif config['adapter'] == 'sqlite3'
  puts "  ... Using Sqlite database"
  system("sqlite3 #{config['database']} < seed_verses.sql")
else
  puts "WARNING: FinalVerse data could not be seeded for #{config['adapter']}. Please see db/seeds.rb."
end

# ----------------------------------------------------------------------------------------------------------
# Seed the forum
# ----------------------------------------------------------------------------------------------------------
# frozen_string_literal: true

# rubocop:disable HandleExceptions
begin
  if FactoryGirl.factories.instance_variable_get(:@items).none?
    require_relative '../spec/factories'
  end
rescue NameError
end
# rubocop:enable HandleExceptions

module Thredded
  class SeedDatabase
    attr_reader :user, :users, :messageboard, :topics, :private_topics, :posts

    SKIP_CALLBACKS = [
      [Thredded::Post, :commit, :after, :auto_follow_and_notify],
      [Thredded::PrivatePost, :commit, :after, :notify_users],
    ].freeze

    def self.run(users: 200, topics: 55, posts: (1..60))
      STDERR.puts 'Seeding the forum'
      # Disable callbacks to avoid creating notifications and performing unnecessary updates
      SKIP_CALLBACKS.each { |(klass, *args)| klass.skip_callback(*args) }
      s = new
      Messageboard.transaction do
        s.create_first_user
        s.create_users(count: users)
        s.create_messageboard
        s.create_topics(count: topics)
        s.create_posts(count: posts)
        s.create_private_posts(count: posts)
        s.create_additional_messageboards
        s.log 'Running after_commit callbacks'
      end
    ensure
      # Re-enable callbacks
      SKIP_CALLBACKS.each { |(klass, *args)| klass.set_callback(*args) }
    end

    def log(message)
      STDERR.puts "- #{message}"
    end

    def create_first_user
      # @user ||= ::User.first || FactoryGirl.create(:user, :approved, :admin, name: 'Joe', email: 'joe@example.com')
      @user = ::User.first   
    end

    def create_users(count:)
      log "Creating #{count} users..."
      approved_users_count = (count * 0.97).round
      @users = [user] +
               FactoryGirl.create_list(:user, approved_users_count, :approved) +
               FactoryGirl.create_list(:user, count - approved_users_count)
    end

    def create_messageboard
      log 'Creating a messageboard...'
      @messageboard = FactoryGirl.create(
        :messageboard,
        name:        'Main Board',
        slug:        'main-board',
        description: 'A board is not a board without some posts'
      )
    end

    def create_additional_messageboards
      meta_group_id = MessageboardGroup.create!(name: 'Meta').id
      additional_messageboards = [
        ['Off-Topic', "Talk about whatever here, it's all good."],
        ['Help, Bugs, and Suggestions',
         'Need help using the forum? Want to report a bug or make a suggestion? This is the place.', meta_group_id],
        ['Praise', 'Want to tell us how great we are? This is the place.', meta_group_id]
      ]
      log "Creating #{additional_messageboards.length} additional messageboards..."
      additional_messageboards.each do |(name, description, group_id)|
        messageboard = Messageboard.create!(name: name, description: description, messageboard_group_id: group_id)
        FactoryGirl.create_list(:topic, 1 + rand(3), messageboard: messageboard, with_posts: 1)
      end
    end

    def create_topics(count: 26, messageboard: self.messageboard)
      log "Creating #{count} topics in #{messageboard.name}..."
      @topics = FactoryGirl.create_list(
        :topic, count,
        messageboard: messageboard,
        user:         users.sample,
        last_user:    users.sample
      )

      @private_topics = FactoryGirl.create_list(
        :private_topic, count,
        user:      users.sample,
        last_user: users.sample,
        users:     [user]
      )
    end

    def create_posts(count: (1..30))
      log "Creating #{count} additional posts in each topic..."
      @posts = topics.flat_map do |topic|
        (count.min + rand(count.max + 1)).times do
          FactoryGirl.create(:post, postable: topic, messageboard: messageboard, user: users.sample)
        end
      end
    end

    def create_private_posts(count: (1..30))
      log "Creating #{count} additional posts in each private topic..."
      @private_posts = private_topics.flat_map do |topic|
        (count.min + rand(count.max + 1)).times do
          FactoryGirl.create(:private_post, postable: topic, user: users.sample)
        end
      end
    end
  end
end

Thredded::SeedDatabase.run




puts "--- Done -----------------"

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

