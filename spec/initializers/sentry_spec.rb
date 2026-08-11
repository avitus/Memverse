require 'rails_helper'

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
end
