class ForumReviewNotifier

  include Sidekiq::Worker
  include Thredded::UrlsHelper

  sidekiq_options :retry => false # ALV - setting to false for now since this job is flooding log file

  def perform
    AdminMailer.forum_review.deliver
  end

end
