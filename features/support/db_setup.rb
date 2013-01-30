begin
  require 'database_cleaner'
  require 'database_cleaner/cucumber'

  DatabaseCleaner.strategy = :transaction

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
    system("mysql --user=#{config['username']} --password=#{config['password']} #{config['database']} < iso_final_verses.sql")
  elsif config['adapter'] == 'sqlite3'
    system("sqlite3 #{config['database']} < iso_final_verses.sql")
  else
    puts "WARNING: FinalVerse data could not be seeded for #{config['adapter']}. Please see db/seeds.rb."
  end

end

After do |scenario|
  DatabaseCleaner.clean
end

