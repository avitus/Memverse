class LastAndScheduledTicksWorker
  include Sidekiq::Worker
  include Sidetiq::Schedulable

  recurrence { hourly }

  def perform(last_tick, scheduled_tick)
  end
end

