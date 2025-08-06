RSpec.configure do |config|
  # Configure DatabaseCleaner for RSpec tests
  # Exclude final_verses table to preserve FinalVerse data loaded by final_verse_data.rb
  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation, except: %w[final_verses])
    DatabaseCleaner.strategy = :truncation, {except: %w[final_verses]}
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end