class AdminMailer < ActionMailer::Base

  # Email admins with forem topics and posts needing review
  def forum_review
    posts  = Forem::Post.pending_review
    topics = Forem::Topic.pending_review

    if posts.present? || topics.present? # don't send if nothing to review
      # code here to send message
    end
  end
end
