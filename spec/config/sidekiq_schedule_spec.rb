require 'rails_helper'
require 'fugit'

# Guards config/sidekiq_schedule.yml, which the Sidekiq scheduler process loads at boot
# (see config/initializers/sidekiq.rb). Every cron expression must carry an explicit UTC
# zone: sidekiq-cron resolves an unzoned expression through et-orbi, which prefers
# ENV['TZ'] over Rails' Time.zone, so a server with TZ exported (or a Pacific system clock
# plus an export) would silently move the quizzes by seven hours. Pinning the zone makes
# the schedule independent of the host.
#
# It also guards against the October 2026 incident (documentation/QUIZ_CRON_DUPLICATE_RUNS_2026-10.md):
# a test entry for KnowledgeQuiz was left in the file with `active: false`, a key sidekiq-cron
# does not know, so the entry stayed enabled and the live quiz started every 40 minutes.
RSpec.describe 'config/sidekiq_schedule.yml' do
  schedule_path = Rails.root.join('config/sidekiq_schedule.yml')
  schedule = YAML.load_file(schedule_path)

  # The per-entry keys Sidekiq::Cron::Job#initialize reads in sidekiq-cron 2.4
  # (lib/sidekiq/cron/job.rb). Anything else is silently ignored, which is exactly how
  # `active: false` failed to disable a job. `status: disabled` is the only off switch.
  sidekiq_cron_keys = %w[
    cron class queue active_job status description args namespace symbolize_args
    date_as_argument retry
  ].freeze

  it 'defines the production schedule' do
    expect(schedule.keys).to include(
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

      it 'uses only keys that sidekiq-cron 2.4 understands' do
        unknown = job.keys - sidekiq_cron_keys
        message = "#{name} uses key(s) #{unknown.inspect} that sidekiq-cron ignores. " \
                  'The only way to switch an entry off is `status: disabled`; ' \
                  'to remove it, delete the entry (the loader destroys removed jobs at boot).'
        expect(unknown).to be_empty, message
      end
    end
  end

  describe 'KnowledgeQuiz entries' do
    quiz_entries = schedule.select { |_, job| job['class'] == 'KnowledgeQuiz' }

    # Enumerate every firing from a fixed UTC start, then slide a 7-day window across
    # the first four weeks an hour at a time. Any window must contain exactly two
    # firings: one Tuesday quiz and one Saturday quiz.
    window_start = Time.utc(2026, 10, 1, 0, 0, 0)
    horizon      = window_start + 35.days
    firings = quiz_entries.flat_map do |_, job|
      cron = Fugit.parse_cron(job['cron'])
      times = []
      t = window_start - 1
      while (t = cron.next_time(t).to_t.utc) < horizon
        times << t
      end
      times
    end.sort

    it 'fires exactly twice in any 7-day window' do
      (0...(28 * 24)).each do |hour|
        from = window_start + hour.hours
        to   = from + 7.days
        count = firings.count { |t| t >= from && t < to }
        expect(count).to eq(2),
          "KnowledgeQuiz fires #{count} times between #{from.iso8601} and #{to.iso8601}; expected exactly 2 " \
          "(Tuesday 17:00 UTC and Saturday 23:00 UTC). Entries: #{quiz_entries.keys.inspect}"
      end
    end

    it 'has no entry that is still present but disabled' do
      disabled = quiz_entries.select { |_, job| job['status'] == 'disabled' }.keys
      expect(disabled).to be_empty, "Remove #{disabled.inspect} from the schedule rather than disabling it"
    end
  end

  it 'keeps the Tuesday quiz at 17:00 UTC regardless of the process time zone' do
    cron = Fugit.parse_cron(schedule.fetch('schedule_knowledge_quiz_tuesday')['cron'])
    next_run = cron.next_time(Time.utc(2026, 10, 7, 0, 0, 0)).to_t.utc
    expect(next_run).to eq(Time.utc(2026, 10, 13, 17, 0, 0))
  end

  it 'keeps the Saturday quiz at 23:00 UTC regardless of the process time zone' do
    cron = Fugit.parse_cron(schedule.fetch('schedule_knowledge_quiz_saturday')['cron'])
    next_run = cron.next_time(Time.utc(2026, 10, 7, 0, 0, 0)).to_t.utc
    expect(next_run).to eq(Time.utc(2026, 10, 10, 23, 0, 0))
  end

  describe 'config/initializers/sidekiq.rb' do
    # Re-run the initializer as the scheduler process would see it, with the real server
    # configuration replaced by a null object so nothing in the test process is altered.
    # The bang loader is what destroys entries that were removed from the YAML; the
    # plain load_from_hash leaves them registered in Redis and firing.
    it 'loads the schedule with load_from_hash! so removed entries are destroyed at boot' do
      stub_const('ENV', ENV.to_h.merge('SIDEKIQ_SCHEDULER' => 'true'))
      server_config = double('Sidekiq server config').as_null_object
      allow(Sidekiq).to receive(:configure_server).and_yield(server_config)
      allow(Sidekiq).to receive(:configure_client)
      allow(Sidekiq).to receive(:default_job_options=)

      expect(Sidekiq::Cron::Job).to receive(:load_from_hash!)
        .with(hash_including('schedule_knowledge_quiz_tuesday', 'schedule_knowledge_quiz_saturday'), source: 'schedule')
        .and_return({})
      expect(Sidekiq::Cron::Job).not_to receive(:load_from_hash)

      load Rails.root.join('config/initializers/sidekiq.rb')
    end
  end
end
