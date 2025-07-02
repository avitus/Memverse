# Load FinalVerse data for RSpec tests
# This ensures that the validate_ref validation in the Verse model has the necessary data

RSpec.configure do |config|
  config.before(:suite) do
    # Load FinalVerse data from the SQL file
    # Only load if the table is empty to avoid duplicate key errors
    if FinalVerse.count == 0
      config = ActiveRecord::Base.configurations[Rails.env]
      if config['adapter'] == 'mysql2'
        system("mysql --user=#{config['username']} --password=\"#{config['password']}\" --host=#{config['host']} #{config['database']} < iso_final_verses.sql")
      elsif config['adapter'] == 'sqlite3'
        system("sqlite3 #{config['database']} < iso_final_verses.sql")
      else
        puts "WARNING: FinalVerse data could not be seeded for #{config['adapter']}. Please see spec/support/final_verse_data.rb."
      end
      puts "Loaded #{FinalVerse.count} FinalVerse records for testing"
    else
      puts "FinalVerse data already exists (#{FinalVerse.count} records), skipping load"
    end
  end
end 