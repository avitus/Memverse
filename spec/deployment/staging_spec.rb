require 'spec_helper'
require 'open3'

RSpec.describe 'Staging deployment isolation' do
  it 'uses only open-source Passenger directives in the staging vhost' do
    config = File.read(File.expand_path('../../deployment_scripts/staging/nginx.conf', __dir__))
    expect(config).not_to match(/^\s*passenger_max_instances\s/)
    expect(config).to include('passenger_app_group_name memverse_staging;')
  end

  it 'deploys to its own path without migrations or production service operations' do
    output, status = Open3.capture2e('bundle', 'exec', 'cap', 'staging', 'deploy', '--dry-run')

    expect(status.success?).to be(true), output
    expect(output).to include('/home/avitus/staging.memverse.com/releases/')
    expect(output).to include('git archive staging')
    expect(output).to include('migrations are disabled')
    expect(output).not_to match(/systemctl|db:migrate|thinking_sphinx:index|ts:configure|ts:stop/)
    expect(output).not_to include('/home/avitus/memverse.com/')
    expect(output).not_to include('gem install', 'update_rubygems')
  end
end
