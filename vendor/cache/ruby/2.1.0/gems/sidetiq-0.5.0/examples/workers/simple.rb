class Simple
  include Sidekiq::Worker
  include Sidetiq::Schedulable

  recurrence { secondly }

  def perform(*args)
  end
end

