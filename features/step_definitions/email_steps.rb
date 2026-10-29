# Email steps used by the features. The EmailHelpers module adapts email_spec's
# mailbox helpers to action_mailer_cache_delivery, which @javascript scenarios
# use so the Selenium-driven server process and the test process share emails.
#
# Helper methods from email_spec that these steps rely on:
#   last_email_address, reset_mailer, unread_emails_for, mailbox_for,
#   current_email, open_email, find_email, visit_in_email

module EmailHelpers
  def current_email_address
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
# Check how many emails have been sent/received
#

Then /^(?:I|they|"([^"]*?)") should receive (an|no|\d+) emails?$/ do |address, amount|
  # Remember this email address for subsequent steps that don't specify an address
  remember_email_for_test(address) if address.present?
  expect(unread_emails_for(address).size).to eq(parse_email_count(amount))
end

Then /^(?:I|they|"([^"]*?)") should receive (an|no|\d+) emails? with subject "([^"]*?)"$/ do |address, amount, subject|
  expect(unread_emails_for(address).select { |m| m.subject =~ Regexp.new(Regexp.escape(subject)) }.size).to eq(parse_email_count(amount))
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

#
# Inspect the Email Contents
#

Then /^(?:I|they) should see "([^"]*?)" in the email body$/ do |text|
  expect(current_email.default_part_body.to_s).to include(text)
end

#
# Interact with Email Contents
#

When /^(?:I|they|"([^"]*?)") follows? "([^"]*?)" in the email$/ do |address, link|
  visit_in_email(link, address)
end

# Step to clear all emails from mailboxes
Given /^all emails have been delivered$/ do
  reset_mailer
  # Also clear cached emails if using cache delivery
  ActionMailer::Base.clear_cache if ActionMailer::Base.delivery_method == :cache
end
