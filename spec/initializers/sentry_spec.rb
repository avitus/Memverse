require 'rails_helper'
require 'sentry/test_helper'

RSpec.describe 'Sentry configuration' do
  let(:config) { Sentry.configuration }

  it 'is initialized' do
    expect(Sentry.initialized?).to be true
  end

  it 'sends events only from production' do
    expect(config.enabled_environments).to eq(['production'])
  end

  it 'points at the memverse Sentry project' do
    expect(config.dsn.public_key).to eq('a1106f25de724396a866c6ab9386b11b')
    expect(config.dsn.project_id.to_s).to eq('299442')
    expect(config.dsn.host).to eq('sentry.io')
  end

  it 'does not send personally identifiable information' do
    expect(config.send_default_pii).to be false
  end

  it 'records ActiveSupport breadcrumbs' do
    expect(config.breadcrumbs_logger).to include(:active_support_logger)
  end

  # Postmark errors, mysql2 SQL breadcrumbs (literal values, no binds) and
  # request params all carry users' addresses, and send_default_pii does not
  # cover any of them.
  describe 'email addresses in captured events' do
    include Sentry::TestHelper

    let(:address) { 'someone@example.com' }
    let(:event_json) { sentry_events.last.to_json_compatible.to_json }
    let!(:original_client) { Sentry.get_current_client }

    before { setup_sentry_test }

    # teardown_sentry_test leaves its enabled dummy client bound for later specs
    after do
      teardown_sentry_test
      Sentry.get_main_hub.bind_client(original_client)
    end

    it 'redacts the address in an exception message' do
      Sentry.capture_exception(postmark_invalid_email_request_error(address))

      expect(sentry_events.last.exception.values.last.value)
        .to eq("Invalid 'To' address: '[email redacted]'. (Postmark::InvalidEmailRequestError)")
      expect(event_json).not_to include(address)
    end

    it 'redacts the message, tags, user and contexts but keeps the user id in extra' do
      Sentry.set_tags(recipient: address)
      Sentry.set_user(email: address)
      Sentry.set_context('mail', { to: [address] })
      Sentry.capture_message("Could not reach #{address}", extra: { user_id: 42, to: address })

      expect(event_json).not_to include(address)
      expect(sentry_events.last.extra).to eq(user_id: 42, to: '[email redacted]')
    end

    it 'redacts breadcrumb messages and data' do
      Sentry.add_breadcrumb(Sentry::Breadcrumb.new(
                              category: 'sql.active_record',
                              data: { sql: "SELECT `users`.* FROM `users` WHERE `users`.`email` = '#{address}'" }
                            ))
      Sentry.add_breadcrumb(Sentry::Breadcrumb.new(category: 'mailer', message: "Delivering to #{address}"))
      Sentry.capture_message('Something failed')

      expect(event_json).not_to include(address)
      expect(sentry_events.last.breadcrumbs.peek.message).to eq('Delivering to [email redacted]')
    end

    it 'redacts URL-encoded addresses in request headers' do
      referer = "https://www.memverse.com/users/password/new?email=#{CGI.escape(address)}"
      Sentry.get_current_scope.set_rack_env(Rack::MockRequest.env_for('/users/password', 'HTTP_REFERER' => referer))
      Sentry.capture_message('Something failed')

      expect(event_json).not_to include(CGI.escape(address))
      expect(sentry_events.last.request.headers['Referer'])
        .to eq('https://www.memverse.com/users/password/new?email=[email redacted]')
    end
  end
end
