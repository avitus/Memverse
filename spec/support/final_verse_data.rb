# Load FinalVerse data for RSpec tests
# This ensures that the validate_ref validation in the Verse model has the necessary data

RSpec.configure do |config|
  config.before(:suite) do
    # Load FinalVerse data from the SQL file
    # Only load if the table is empty to avoid duplicate key errors
    if FinalVerse.count == 0
      config = ActiveRecord::Base.configurations.configs_for(env_name: Rails.env).first.configuration_hash
      if config[:adapter] == 'mysql2'
        iso_file_path = Rails.root.join('iso_final_verses.sql')
        password_arg = config[:password] ? "--password=\"#{config[:password]}\"" : ""
        system("mysql --user=#{config[:username]} #{password_arg} --host=#{config[:host]} #{config[:database]} < #{iso_file_path}")
      elsif config[:adapter] == 'sqlite3'
        iso_file_path = Rails.root.join('iso_final_verses.sql')
        system("sqlite3 #{config[:database]} < #{iso_file_path}")
      else
        puts "WARNING: FinalVerse data could not be seeded for #{config[:adapter]}. Please see spec/support/final_verse_data.rb."
      end
      puts "Loaded #{FinalVerse.count} FinalVerse records for testing"
    else
      puts "FinalVerse data already exists (#{FinalVerse.count} records), skipping load"
    end

    # Add specific FinalVerse records needed by quest specs
    required_chapters = [
      ['Psalms', 8, 9],
      ['Psalms', 11, 7],
      ['Psalms', 12, 8],
      ['Psalms', 13, 6],
      ['Psalms', 14, 7],
      ['Psalms', 23, 6],
      ['Psalms', 24, 10],
      ['Psalms', 53, 6],
      ['Psalms', 117, 2],
      ['Esther', 10, 3],
      ['Jude', 1, 25]
    ]

    required_chapters.each do |book, chapter, last_verse|
      unless FinalVerse.exists?(book: book, chapter: chapter)
        FinalVerse.create!(book: book, chapter: chapter, last_verse: last_verse)
      end
    end
  end
end 