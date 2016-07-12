class AdminMailer < ActionMailer::Base

  default :from => '"Memverse" <admin@memverse.com>'

  require 'mail'

  # Email admins with forem topics and posts needing review
  # def forum_review
  #   @posts  = Forem::Post.pending_review
  #   @topics = Forem::Topic.pending_review

  #   if @posts.present? || @topics.present? # don't send if nothing to review
  #     emails = %w(admin@memverse.com alexcwatt@memverse.com)

  #     mail(to: emails, subject: "Forum: Posts and topics to review")
  #   end
  # end
end
