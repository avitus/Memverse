class ForumReviewNotifier

  include Sidekiq::Worker
  include Sidetiq::Schedulable

  sidekiq_options :retry => true

  recurrence do
     daily.hour_of_day(8)
  end

  def perform
    AdminMailer.forum_review.deliver
  end

end
