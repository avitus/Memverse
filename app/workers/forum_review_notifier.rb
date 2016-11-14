class ForumReviewNotifier

  include Sidekiq::Worker
  include Sidetiq::Schedulable
  include Thredded::UrlsHelper

  sidekiq_options :retry => false # ALV - setting to false for now since this job is flooding log file

  recurrence do
     daily.hour_of_day(8)
  end

  def perform
    AdminMailer.forum_review.deliver
  end

end
