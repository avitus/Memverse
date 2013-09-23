class UpdateMetrics

  include Sidekiq::Worker
  include Sidetiq::Schedulable

  sidekiq_options :retry => true

  recurrence do
     daily.hour_of_day(12)
  end

  def perform
    DailyStats.update()
  end

end
