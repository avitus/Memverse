AfterStep('@pause') do
  print "Press Return to continue ..."
  STDIN.getc
end

# Email handling for JavaScript tests
Before('@javascript') do
  # Enable cached delivery for JavaScript scenarios to share emails between processes
  ENV['CACHE_EMAILS'] = 'true'
  ActionMailer::Base.delivery_method = :cache
  ActionMailer::Base.perform_deliveries = true
  
  # Clear the email cache before each JavaScript test
  begin
    ActionMailer::Base.clear_cache if ActionMailer::Base.respond_to?(:clear_cache)
  rescue StandardError => e
    # Handle any errors with cache clearing, including file locking issues
    Rails.logger.warn "Failed to clear email cache: #{e.class} - #{e.message}" if Rails.logger
    # Clear deliveries array as a fallback
    ActionMailer::Base.deliveries.clear if ActionMailer::Base.respond_to?(:deliveries)
  end
end

After('@javascript') do
  # Clean up cached emails after JavaScript tests
  begin
    ActionMailer::Base.clear_cache if ActionMailer::Base.respond_to?(:clear_cache)
  rescue StandardError => e
    Rails.logger.warn "Failed to clear email cache: #{e.class} - #{e.message}" if Rails.logger
  end
  
  # Also clear the test deliveries array that cache delivery adds to
  ActionMailer::Base.deliveries.clear if ActionMailer::Base.respond_to?(:deliveries)
  
  # Reset to test delivery method for non-JavaScript tests
  ENV['CACHE_EMAILS'] = 'false'
  ActionMailer::Base.delivery_method = :test
end

Before('not @javascript') do
  # Ensure test delivery method is used for non-JavaScript tests
  ActionMailer::Base.delivery_method = :test
  ActionMailer::Base.perform_deliveries = true
end