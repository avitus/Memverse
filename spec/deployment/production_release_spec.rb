require 'open3'

RSpec.describe 'Production Capistrano releases' do
  def rehearse(task = 'deploy', failure: nil, fenced: false)
    env = { 'FAIL_COMMAND' => failure, 'SKIP_SIDEKIQ_START' => fenced ? '1' : nil }
    output, status = Open3.capture2e(env, 'bundle', 'exec', 'cap', '--dry-run',
                                     '-f', 'spec/deployment/fixtures/Capfile', 'production', task)
    expect(status.success?).to eq(failure.nil?), output
    expect(output).to include('Simulated release failure') if failure
    output
  end

  let(:stop) { 'sudo systemctl stop sidekiq-scheduler' }
  let(:workers_stop) { "sudo systemctl stop 'sidekiq-workers@*'" }
  let(:start) { 'sudo systemctl start sidekiq-scheduler' }
  let(:publish) { 'mv /home/avitus/memverse.com/releases/current' }

  it 'reuses installed gems and compiles once before stopping jobs for migrations' do
    output = rehearse
    expect(output).to include('dependencies are satisfied', "assets:clean[2]", 'assets_manifest_backup')
    expect(output).not_to match(%r{rm -rf [^\n]*shared/bundle|assets:clobber})
    expect(output.scan(/bundle exec (?:rake|rails) assets:precompile/).size).to eq(1)
    expect(output.scan(stop).size).to eq(1)
    expect(output).to match(/rake assets:precompile.*#{stop}.*#{Regexp.escape(workers_stop)}.*rake db:migrate.*#{publish}.*#{start}/m)
  end

  it 'restores the previous manifest and switches releases with the workers stopped on rollback' do
    output = rehearse('deploy:rollback')
    expect(output).to match(/cp [^\n]*assets_manifest_backup.*#{stop}.*#{publish}.*#{start}/m)
    expect(output).not_to match(/rake db:migrate|rake assets:precompile/)
  end

  it 'leaves the live workers running when asset compilation fails' do
    expect(rehearse(failure: 'assets:precompile')).not_to include(stop, publish)
  end

  it 'aborts before changing the schema when stopping a worker fails' do
    output = rehearse(failure: "systemctl stop 'sidekiq-workers@*'")
    expect(output).to include(stop)
    expect(output).not_to include('rake db:migrate', publish, start)
  end

  it 'leaves jobs stopped when a migration fails' do
    output = rehearse(failure: 'rake db:migrate')
    expect(output).to include(stop)
    expect(output).not_to include(publish, start)
  end

  it 'leaves jobs stopped when rollback cannot publish the previous release' do
    output = rehearse('deploy:rollback', failure: 'mv /home/avitus/memverse.com/releases/current')
    expect(output).to include(stop)
    expect(output).not_to include(start)
  end

  it 'stops fenced hosts before preparation and never starts jobs on them' do
    output = rehearse(fenced: true)
    expect(output).to match(/#{stop}.*bundler:install.*#{publish}/m)
    expect(output).not_to include(start)
  end
end
