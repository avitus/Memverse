require 'rails_helper'
require 'fugit'

# Guards config/sidekiq_schedule.yml, which the Sidekiq scheduler process loads at boot
# (see config/initializers/sidekiq.rb). Every cron expression must carry an explicit UTC
# zone: sidekiq-cron resolves an unzoned expression through et-orbi, which prefers
# ENV['TZ'] over Rails' Time.zone, so a server with TZ exported (or a Pacific system clock
# plus an export) would silently move the quizzes by seven hours. Pinning the zone makes
# the schedule independent of the host.
RSpec.describe 'config/sidekiq_schedule.yml' do
  schedule_path = Rails.root.join('config', 'sidekiq_schedule.yml')
  schedule = YAML.load_file(schedule_path)

  it 'defines the production schedule' do
    expect(schedule.keys).to include(
      'schedule_quiz',
      'schedule_send_reminders',
      'schedule_knowledge_quiz_tuesday',
      'schedule_knowledge_quiz_saturday',
      'schedule_forum_review_notifier',
      'schedule_update_metrics'
    )
  end

  schedule.each do |name, job|
    describe name do
      it 'has a cron expression that Fugit parses' do
        expect(Fugit.parse_cron(job['cron'])).to be_a(Fugit::Cron), "#{job['cron'].inspect} did not parse"
      end

      it 'pins the cron expression to UTC' do
        expect(Fugit.parse_cron(job['cron']).zone).to eq('UTC'), "#{name}: #{job['cron'].inspect} has no explicit UTC zone"
      end

      it 'names a worker class that exists' do
        expect { job['class'].constantize }.not_to raise_error
      end

      it 'routes to a configured queue' do
        expect(%w[critical high default low scheduler]).to include(job['queue'])
      end
    end
  end

  it 'keeps the Tuesday quiz at 17:00 UTC regardless of the process time zone' do
    cron = Fugit.parse_cron(schedule.fetch('schedule_knowledge_quiz_tuesday')['cron'])
    next_run = cron.next_time(Time.utc(2026, 10, 7, 0, 0, 0)).to_t.utc
    expect(next_run).to eq(Time.utc(2026, 10, 13, 17, 0, 0))
  end
end
