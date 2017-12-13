class UpdateMetrics

  include Sidekiq::Worker

  sidekiq_options :retry => true

  def perform
    DailyStats.update()
  end

end
