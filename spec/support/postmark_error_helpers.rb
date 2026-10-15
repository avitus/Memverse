# frozen_string_literal: true

# Builds the errors postmark-rails raises when the Postmark API refuses a
# message, and makes the test mailer raise them, so specs can exercise the
# same failure path production hits inside Mail::Message#deliver.
module PostmarkErrorHelpers
  def postmark_inactive_recipient_error(address)
    postmark_api_input_error(
      Postmark::InactiveRecipientError, 406,
      'You tried to send to recipient(s) that have been marked as inactive. ' \
      "Found inactive addresses: #{address}. Inactive recipients are ones that " \
      'have generated a hard bounce, a spam complaint, or a manual suppression.'
    )
  end

  def postmark_invalid_email_request_error(address)
    postmark_api_input_error(Postmark::InvalidEmailRequestError, 300, "Invalid 'To' address: '#{address}'.")
  end

  def stub_mail_delivery_failure(error)
    allow_any_instance_of(Mail::TestMailer).to receive(:deliver!).and_raise(error)
  end

  private

  def postmark_api_input_error(klass, error_code, message)
    parsed_body = { 'ErrorCode' => error_code, 'Message' => message }
    klass.new(error_code, parsed_body.to_json, parsed_body)
  end
end

RSpec.configure do |config|
  config.include PostmarkErrorHelpers
end
