class AdminMailer < ActionMailer::Base

  default :from => '"Memverse" <admin@memverse.com>'

  require 'mail'

  # Email admins with forem topics and posts needing review
  def forum_review
    @posts  = Thredded::Post.pending_moderation
    # @topics = Thredded::Topic.pending_moderation

    if @posts.present? # || @topics.present?
      emails = %w(admin@memverse.com alexcwatt@memverse.com)
      mail(
        to: emails,
        subject: "Forum: Posts and topics to review",
        tag: "forum-review",
        message_stream: "forum-stream"
      )
    end
  end

  # Alert when ActiveJob is misconfigured
  def sidekiq_misconfiguration_alert(current_adapter)
    @adapter = current_adapter
    emails = %w(admin@memverse.com alexcwatt@memverse.com)
    mail(
      to: emails,
      subject: "[CRITICAL] ActiveJob not using Sidekiq - site performance degraded",
      tag: "critical-alert",
      message_stream: "outbound"
    )
  end

  # Alert when Sidekiq processes are not running
  def sidekiq_not_running_alert
    emails = %w(admin@memverse.com alexcwatt@memverse.com)
    mail(
      to: emails,
      subject: "[CRITICAL] No Sidekiq processes running - background jobs not processing",
      tag: "critical-alert",
      message_stream: "outbound"
    )
  end

  # Alert on high queue latency
  def high_queue_latency_alert(queue_name, latency)
    @queue_name = queue_name
    @latency = latency
    emails = %w(admin@memverse.com alexcwatt@memverse.com)
    mail(
      to: emails,
      subject: "[WARNING] High latency in #{queue_name} queue: #{latency.round}s",
      tag: "warning-alert",
      message_stream: "outbound"
    )
  end

end
