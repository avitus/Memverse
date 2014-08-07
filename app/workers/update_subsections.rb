class KnowledgeQuiz

  include Sidekiq::Worker
  include Sidetiq::Schedulable
  include IceCube

  sidekiq_options :retry => false

  recurrence do
    monthly.day_of_month(5).hour_of_day(1)    # Every Sunday at 9am
  end

  def perform

  end

end