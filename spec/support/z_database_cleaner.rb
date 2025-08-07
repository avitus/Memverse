RSpec.configure do |config|
  # Configure DatabaseCleaner for RSpec tests
  # Exclude final_verses table to preserve FinalVerse data loaded by final_verse_data.rb
  config.before(:suite) do
    DatabaseCleaner[:active_record].clean_with(:truncation, except: %w[final_verses])
  end

  config.before(:each) do |example|
    # Disable background jobs during tests to prevent deadlocks
    ActiveJob::Base.queue_adapter = :test
    
    # Use truncation for tests that involve complex data setup or heavy database usage
    if example.metadata[:heavy_db] || example.full_description.include?('subsection')
      DatabaseCleaner[:active_record].strategy = :truncation, {except: %w[final_verses]}
    else
      # Use transaction strategy for most tests for better performance
      DatabaseCleaner[:active_record].strategy = :transaction
    end
    DatabaseCleaner[:active_record].start
  end

  config.after(:each) do
    DatabaseCleaner[:active_record].clean
  end

  # Ensure test isolation by using different schema for each test run
  config.around(:each) do |example|
    begin
      example.run
    rescue ActiveRecord::Deadlocked, Mysql2::Error => e
      # Retry once on deadlock or table definition change
      Rails.logger.warn "Database error in test, retrying: #{e.message}"
      sleep 0.1
      DatabaseCleaner[:active_record].clean
      DatabaseCleaner[:active_record].start
      example.run
    end
  end
end