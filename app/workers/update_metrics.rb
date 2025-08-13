class UpdateMetrics

  include Sidekiq::Worker

  sidekiq_options queue: :default, retry: true

  def perform
    DailyStats.update()
  end

end
