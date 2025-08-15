# Commonly used email steps
#
# To add your own steps make a custom_email_steps.rb
# The provided methods are:
#
# last_email_address
# reset_mailer
# open_last_email
# visit_in_email
# unread_emails_for
# mailbox_for
# current_email
# open_email
# read_emails_for
# find_email
#
# General form for email scenarios are:
#   - clear the email queue (done automatically by email_spec)
#   - execute steps that sends an email
#   - check the user received an/no/[0-9] emails
#   - open the email
#   - inspect the email contents
#   - interact with the email (e.g. click links)
#
# The Cucumber steps below are setup in this order.

module EmailHelpers
  def current_email_address
    # Replace with your a way to find your current email. e.g @current_user.email
    # last_email_address will return the last email address used by email spec to find an email.
    # Note that last_email_address will be reset after each Scenario.
    last_email_address || @current_user&.email || @last_signup_email
  end
  
  def remember_email_for_test(email)
    @last_signup_email = email
  end
  
  # Helper methods for action_mailer_cache_delivery integration
  def cached_emails
    return [] unless ActionMailer::Base.delivery_method == :cache
    ActionMailer::Base.cached_deliveries
  end
  
  def cached_emails_for(address)
    address = address.strip if address.is_a?(String)
    cached_emails.select do |email|
      email_addresses = [email.to, email.cc, email.bcc].flatten.compact
      email_addresses.any? { |addr| addr.strip == address }
    end
  end
  
  def reset_cached_emails
    ActionMailer::Base.clear_cache if ActionMailer::Base.delivery_method == :cache
  end
  
  # Override email_spec methods to work with cached emails in JavaScript tests
  def mailbox_for(address)
    if ActionMailer::Base.delivery_method == :cache
      email_address = address.present? ? address : current_email_address
      cached_emails_for(email_address)
    else
      super
    end
  end
  
  def unread_emails_for(address)
    if ActionMailer::Base.delivery_method == :cache
      email_address = address.present? ? address : current_email_address
      cached_emails_for(email_address)
    else
      super
    end
  end
  
  def read_emails_for(address)
    if ActionMailer::Base.delivery_method == :cache
      email_address = address.present? ? address : current_email_address
      cached_emails_for(email_address)
    else
      super
    end
  end
  
  def find_email(address, opts={})
    if ActionMailer::Base.delivery_method == :cache
      emails = cached_emails_for(address)
      if opts[:with_subject]
        pattern = opts[:with_subject].is_a?(Regexp) ? opts[:with_subject] : /#{Regexp.escape(opts[:with_subject])}/
        emails = emails.select { |m| m.subject =~ pattern }
      end
      if opts[:with_text]
        pattern = opts[:with_text].is_a?(Regexp) ? opts[:with_text] : /#{Regexp.escape(opts[:with_text])}/
        emails = emails.select { |m| m.default_part_body.to_s =~ pattern }
      end
      emails.last
    else
      super
    end
  end
  
  def open_email(address, opts={})
    if ActionMailer::Base.delivery_method == :cache
      # Use current_email_address if no address provided (e.g., when step uses "I")
      email_address = address.present? ? address : current_email_address
      @current_email = find_email(email_address, opts)
      raise "Could not find email for #{email_address}" unless @current_email
      @current_email
    else
      super
    end
  end
  
  def current_email
    if ActionMailer::Base.delivery_method == :cache
      @current_email
    else
      super
    end
  end
end

World(EmailHelpers)

# Parse email count from natural language
def parse_email_count(amount)
  case amount
  when 'an', 'a'
    1
  when 'no'
    0
  else
    amount.to_i
  end
end

#
# Reset the e-mail queue within a scenario.
# This is done automatically before each scenario.
#

Given /^(?:a clear email queue|no emails have been sent)$/ do
  if ActionMailer::Base.delivery_method == :cache
    # For JavaScript tests using cached delivery
    ActionMailer::Base.clear_cache
  else
    # For regular tests using test delivery
    reset_mailer
  end
end

#
# Check how many emails have been sent/received
#

Then /^(?:I|they|"([^"]*?)") should receive (an|no|\d+) emails?$/ do |address, amount|
  # Remember this email address for subsequent steps that don't specify an address
  remember_email_for_test(address) if address.present?
  expect(unread_emails_for(address).size).to eq(parse_email_count(amount))
end

Then /^(?:I|they|"([^"]*?)") should have (an|no|\d+) emails?$/ do |address, amount|
  mailbox_for(address).size.should == parse_email_count(amount)
end

Then /^(?:I|they|"([^"]*?)") should receive (an|no|\d+) emails? with subject "([^"]*?)"$/ do |address, amount, subject|
  unread_emails_for(address).select { |m| m.subject =~ Regexp.new(Regexp.escape(subject)) }.size.should == parse_email_count(amount)
end

Then /^(?:I|they|"([^"]*?)") should receive (an|no|\d+) emails? with subject \/([^"]*?)\/$/ do |address, amount, subject|
  unread_emails_for(address).select { |m| m.subject =~ Regexp.new(subject) }.size.should == parse_email_count(amount)
end

Then /^(?:I|they|"([^"]*?)") should receive an email with the following body:$/ do |address, expected_body|
  open_email(address, :with_text => expected_body)
end

#
# Accessing emails
#

# Opens the most recently received email
When /^(?:I|they|"([^"]*?)") opens? the email$/ do |address|
  open_email(address)
end

When /^(?:I|they|"([^"]*?)") opens? the email with subject "([^"]*?)"$/ do |address, subject|
  open_email(address, :with_subject => subject)
end

When /^(?:I|they|"([^"]*?)") opens? the email with subject \/([^"]*?)\/$/ do |address, subject|
  open_email(address, :with_subject => Regexp.new(subject))
end

When /^(?:I|they|"([^"]*?)") opens? the email with text "([^"]*?)"$/ do |address, text|
  open_email(address, :with_text => text)
end

When /^(?:I|they|"([^"]*?)") opens? the email with text \/([^"]*?)\/$/ do |address, text|
  open_email(address, :with_text => Regexp.new(text))
end

#
# Inspect the Email Contents
#

Then /^(?:I|they) should see "([^"]*?)" in the email subject$/ do |text|
  current_email.should have_subject(text)
end

Then /^(?:I|they) should see \/([^"]*?)\/ in the email subject$/ do |text|
  current_email.should have_subject(Regexp.new(text))
end

Then /^(?:I|they) should see "([^"]*?)" in the email body$/ do |text|
  current_email.default_part_body.to_s.should include(text)
end

Then /^(?:I|they) should see \/([^"]*?)\/ in the email body$/ do |text|
  current_email.default_part_body.to_s.should =~ Regexp.new(text)
end

Then /^(?:I|they) should see the email delivered from "([^"]*?)"$/ do |text|
  current_email.should be_delivered_from(text)
end

Then /^(?:I|they) should see "([^\"]*)" in the email "([^"]*?)" header$/ do |text, name|
  current_email.should have_header(name, text)
end

Then /^(?:I|they) should see \/([^\"]*)\/ in the email "([^"]*?)" header$/ do |text, name|
  current_email.should have_header(name, Regexp.new(text))
end

Then /^I should see it is a multi\-part email$/ do
    current_email.should be_multipart
end

Then /^(?:I|they) should see "([^"]*?)" in the email html part body$/ do |text|
    current_email.html_part.body.to_s.should include(text)
end

Then /^(?:I|they) should see "([^"]*?)" in the email text part body$/ do |text|
    current_email.text_part.body.to_s.should include(text)
end

#
# Inspect the Email Attachments
#

Then /^(?:I|they) should see (an|no|\d+) attachments? with the email$/ do |amount|
  current_email_attachments.size.should == parse_email_count(amount)
end

Then /^there should be (an|no|\d+) attachments? named "([^"]*?)"$/ do |amount, filename|
  current_email_attachments.select { |a| a.filename == filename }.size.should == parse_email_count(amount)
end

Then /^attachment (\d+) should be named "([^"]*?)"$/ do |index, filename|
  current_email_attachments[(index.to_i - 1)].filename.should == filename
end

Then /^there should be (an|no|\d+) attachments? of type "([^"]*?)"$/ do |amount, content_type|
  current_email_attachments.select { |a| a.content_type.include?(content_type) }.size.should == parse_email_count(amount)
end

Then /^attachment (\d+) should be of type "([^"]*?)"$/ do |index, content_type|
  current_email_attachments[(index.to_i - 1)].content_type.should include(content_type)
end

Then /^all attachments should not be blank$/ do
  current_email_attachments.each do |attachment|
    attachment.read.size.should_not == 0
  end
end

Then /^show me a list of email attachments$/ do
  EmailSpec::EmailViewer::save_and_open_email_attachments_list(current_email)
end

#
# Interact with Email Contents
#

When /^(?:I|they|"([^"]*?)") follows? "([^"]*?)" in the email$/ do |address, link|
  visit_in_email(link, address)
end

When /^(?:I|they) click the first link in the email$/ do
  click_first_link_in_email
end

#
# Debugging
# These only work with Rails and OSx ATM since EmailViewer uses RAILS_ROOT and OSx's 'open' command.
# Patches accepted. ;)
#

Then /^save and open current email$/ do
  EmailSpec::EmailViewer::save_and_open_email(current_email)
end

Then /^save and open all text emails$/ do
  EmailSpec::EmailViewer::save_and_open_all_text_emails
end

Then /^save and open all html emails$/ do
  EmailSpec::EmailViewer::save_and_open_all_html_emails
end

Then /^save and open all raw emails$/ do
  EmailSpec::EmailViewer::save_and_open_all_raw_emails
end

# Email configuration steps
Given /^email deliveries are enabled$/ do
  ActionMailer::Base.perform_deliveries = true
  # Set thread-local variable for cross-process communication
  Thread.current[:send_emails_in_test] = true
end

Given /^email deliveries are disabled for testing$/ do
  ActionMailer::Base.perform_deliveries = false
end

# Postmark-specific email verification steps
Then /^I should see "([^"]*)" in the email from$/ do |expected_from|
  current_email.from.first.should eq(expected_from)
end

Then /^the email should have tag "([^"]*)"$/ do |expected_tag|
  # Check for Postmark tag header
  if ActionMailer::Base.delivery_method == :cache
    tag_header = current_email.header_fields.find { |h| h.name == 'X-PM-Tag' }
    expect(tag_header).to be_present, "Expected X-PM-Tag header to be present"
    expect(tag_header.value).to eq(expected_tag)
  else
    current_email.should have_header('X-PM-Tag', expected_tag)
  end
end

Then /^the email should have message stream "([^"]*)"$/ do |expected_stream|
  # Check for Postmark message stream header
  if ActionMailer::Base.delivery_method == :cache
    stream_header = current_email.header_fields.find { |h| h.name == 'X-PM-Message-Stream' }
    expect(stream_header).to be_present, "Expected X-PM-Message-Stream header to be present"
    expect(stream_header.value).to eq(expected_stream)
  else
    current_email.should have_header('X-PM-Message-Stream', expected_stream)
  end
end

Then /^the email should have unsubscribe link$/ do
  # Check for List-Unsubscribe header
  if ActionMailer::Base.delivery_method == :cache
    unsubscribe_header = current_email.header_fields.find { |h| h.name == 'List-Unsubscribe' }
    expect(unsubscribe_header).to be_present, "Expected List-Unsubscribe header to be present"
  else
    current_email.headers['List-Unsubscribe'].should be_present
  end
end

Then /^the email should have correct Postmark configuration:$/ do |table|
  table.rows_hash.each do |key, expected_value|
    case key
    when 'tag'
      current_email.should have_header('X-PM-Tag', expected_value)
    when 'message_stream'
      current_email.should have_header('X-PM-Message-Stream', expected_value)
    when 'from'
      current_email.from.first.should eq(expected_value)
    end
  end
end

Then /^the email should have header "([^"]*)" containing "([^"]*)"$/ do |header_name, expected_content|
  if ActionMailer::Base.delivery_method == :cache
    header = current_email.header_fields.find { |h| h.name == header_name }
    expect(header).to be_present, "Expected #{header_name} header to be present"
    expect(header.value.to_s).to include(expected_content)
  else
    header_value = current_email.headers[header_name]
    header_value.should be_present
    header_value.to_s.should include(expected_content)
  end
end

# Email counting and validation steps
Then /^"([^"]*)" should receive only the signup email$/ do |address|
  emails = mailbox_for(address)
  emails.size.should eq(1)
  emails.first.subject.should include("confirm")
end

Then /^"([^"]*)" should receive exactly (\d+) emails total$/ do |address, count|
  mailbox_for(address).size.should eq(count.to_i)
end

Then /^"([^"]*)" should still receive exactly (\d+) emails total$/ do |address, count|
  mailbox_for(address).size.should eq(count.to_i)
end

Then /^the email should be multipart with HTML and text versions$/ do
  current_email.should be_multipart
  current_email.html_part.should be_present
  current_email.text_part.should be_present
end

Then /^both email parts should contain "([^"]*)"$/ do |text|
  current_email.html_part.body.to_s.should include(text)
  current_email.text_part.body.to_s.should include(text)
end

# Removed duplicate - this is already handled by the existing email steps

# Step to clear all emails from mailboxes 
Given /^all emails have been delivered$/ do
  reset_mailer
  # Also clear cached emails if using cache delivery
  ActionMailer::Base.clear_cache if ActionMailer::Base.delivery_method == :cache
end
