class OptionalArgumentWorker
  include Sidekiq::Worker
  include Sidetiq::Schedulable

  recurrence { hourly }

  def perform(last_tick = nil)
  end
end

