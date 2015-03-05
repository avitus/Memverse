class ScheduledWorker
  include Sidekiq::Worker
  include Sidetiq::Schedulable

  recurrence do
    daily.hour_of_day(1)
    yearly.month_of_year(2)
    monthly.day_of_month(3)

    add_exception_rule yearly.month_of_year(:february)
  end

  def perform
  end
end

