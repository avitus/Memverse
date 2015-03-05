class Failing
  include Sidekiq::Worker
  include Sidetiq::Schedulable

  recurrence { secondly }

  def perform(*args)
    if rand(5) == 0
      raise "This didn't go well."
    end
  end
end

