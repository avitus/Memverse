# Load FinalVerse data for RSpec tests
# This ensures that the validate_ref validation in the Verse model has the necessary data

require_relative 'bible_structure'

RSpec.configure do |config|
  config.before(:suite) do
    # Load complete Bible structure data
    # This provides all 1,189 chapters across 66 books
    if FinalVerse.count < 1189
      puts "Loading complete Bible structure data..."
      
      # Use transaction for faster bulk insert
      ActiveRecord::Base.transaction do
        BibleStructure::BOOKS.each do |book, chapters|
          chapters.each do |chapter, last_verse|
            FinalVerse.find_or_create_by!(book: book, chapter: chapter) do |fv|
              fv.last_verse = last_verse
            end
          end
        end
      end
      
      puts "Loaded #{FinalVerse.count} FinalVerse records for testing"
    else
      puts "FinalVerse data already complete (#{FinalVerse.count} records), skipping load"
    end
  end
end 