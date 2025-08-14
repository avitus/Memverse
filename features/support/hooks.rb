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
  ActionMailer::Base.clear_cache
end

After('@javascript') do
  # Clean up cached emails after JavaScript tests
  ActionMailer::Base.clear_cache
  
  # Also clear the test deliveries array that cache delivery adds to
  ActionMailer::Base.deliveries.clear
  
  # Reset to test delivery method for non-JavaScript tests
  ENV['CACHE_EMAILS'] = 'false'
  ActionMailer::Base.delivery_method = :test
end

Before('not @javascript') do
  # Ensure test delivery method is used for non-JavaScript tests
  ActionMailer::Base.delivery_method = :test
  ActionMailer::Base.perform_deliveries = true
end