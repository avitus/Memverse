class SendReminders

  include Sidekiq::Worker

  sidekiq_options queue: :high, retry: false

  def perform
    # TEMPORARY: Disable reminder emails while email provider transition is in progress
    # To re-enable: Comment out or remove the following lines
    # if true  # Set to false to re-enable emails
    #   Rails.logger.info(" *** Email reminder: TEMPORARILY DISABLED - Skipping email reminders")
    #   return
    # end

    @emails_sent        = 0
    @throttle           = 8  # email send limit per hourly run (~192/day max)

    # Delete users who never activated
    User.pending.where('created_at < ?', 2.days.ago ).delete_all

    # Retrieve records for all users ordered by newest first
    # Process newest users first to prioritize recently registered users
    # Note: Using in_batches with order instead of find_each which ignores order
    # IMPORTANT: in_batches loads by primary key, so we need to reorder within each batch
    User.in_batches(of: 100) do |batch|
      # Apply ordering to the batch before iterating to ensure order is preserved
      # This is critical to ensure newest users are processed first within each batch
      batch.reorder(created_at: :desc).each { |u| remind(u) }
    end

    Rails.logger.info(" *** Email reminder: Sent #{@emails_sent} reminder emails at #{Time.now}")

  end

  private

  # Email a user who wants reminders and is behind on memorizing, unless this run has reached the throttle
  # @param u [User]
  def remind(u)
    # Change reminder frequency (if necessary) to not be annoying
    u.update_reminder_freq

    return if u.reminder_freq == "Never" || @emails_sent >= @throttle

    # ==== Users who have added verses but are behind on memorizing ====
    return unless u.needs_reminder?

    # Check for invalid email field
    if valid_email?(u.email)
      Rails.logger.info("* Sending progression email to #{u.name_or_login}. They are at progression level #{u.progression}.")
      send_progression_email(u)
    elsif u.email.blank?
      Rails.logger.info("** Error: Unable to email user with id: #{u.id} - blank email address")
    else
      Rails.logger.warn("** Error: Unable to email user with id: #{u.id} - invalid email format: '#{u.email}'")
    end
  end

  # Deliver the progression email and record it as the user's last reminder
  # @param u [User]
  def send_progression_email(u)
    deliver_progression_email(u)
    @emails_sent += 1
    record_reminder(u)
  rescue Postmark::InactiveRecipientError, Postmark::InvalidEmailRequestError => e
    # When Postmark will not deliver to this user, retrying every hour cannot succeed, so the
    # attempt counts as this cycle's reminder. Postmark's error message contains the address,
    # so only the error code is logged. Invalid requests are still reported because a
    # misconfigured message raises the same error.
    record_reminder(u) if recipient_rejected?(e)
    Rails.logger.warn("** Progression email for user #{u.id} not delivered: #{e.class} (Postmark error #{e.error_code})")
    if e.is_a?(Postmark::InvalidEmailRequestError)
      Sentry.capture_message("Postmark rejected a progression email: #{e.class} (error #{e.error_code})",
                             level: :warning, extra: { user_id: u.id })
    end
  rescue => e
    Rails.logger.error("** Error: Failed to send progression email to user #{u.id}: #{e.class} - #{e.message}")
    # Continue processing other users even if one email fails
  end

  # We need to send an email that is customized for every level of user progression
  # @param u [User]
  def deliver_progression_email(u)
    case u.progression
      when 9
        UserMailer.progression_email_9(u).deliver # has memorized one or more verses
      when 8
        UserMailer.progression_email_8(u).deliver # has completed 3 or more sessions
      when 7
        UserMailer.progression_email_7(u).deliver # has completed 2 sessions
      when 6
        UserMailer.progression_email_6(u).deliver # has completed 1 session
      when 5
        UserMailer.progression_email_5(u).deliver # has reviewed at least one verse at some point
      when 4
        UserMailer.progression_email_4(u).deliver # has added > 5 verses
      when 3
        UserMailer.progression_email_3(u).deliver # has added 1-5 verses
      when 2
        UserMailer.progression_email_2(u).deliver # has confirmed account but added no verses
      when 1
                                                  # User has not confirmed email account
    end
  end

  # Postmark has suppressed the address (hard bounce, spam complaint or manual suppression), or
  # its validation error 300 names the 'To' field ("Invalid 'To' address", "Error parsing 'To'").
  # Error 300 also covers problems with the message itself, such as the sender or a missing body.
  # Those fail for every user, so they are left to retry on the next run.
  # @param e [Postmark::InactiveRecipientError, Postmark::InvalidEmailRequestError]
  def recipient_rejected?(e)
    e.is_a?(Postmark::InactiveRecipientError) || e.message.include?("'To'")
  end

  # Written without validations or callbacks: last_reminder is bookkeeping, and a legacy
  # record that fails a newer validation must still be marked or it is retried every hour
  # @param u [User]
  def record_reminder(u)
    u.update_column(:last_reminder, Time.zone.today) # skipcq: RB-RL1053
  end

  # Validate email format to prevent Postmark errors
  # @param email [String] Email address to validate
  # @return [Boolean] true if email is valid format, false otherwise
  def valid_email?(email)
    return false if email.blank?
    
    # Basic email format validation - must contain @ and have reasonable format
    # This is a more practical validation that will catch obvious invalid emails
    return false unless email.include?('@')
    return false if email.include?(' ')  # No spaces allowed
    return false if email.include?('..') # No double dots allowed
    return false if email.start_with?('@') || email.end_with?('@')
    
    # Split on @ - should have exactly 2 parts
    parts = email.split('@')
    return false unless parts.length == 2
    
    local_part, domain_part = parts
    return false if local_part.empty? || domain_part.empty?
    return false unless domain_part.include?('.') # Domain must have at least one dot
    
    # Basic format check with regex for more complex validation
    email_regex = /\A[a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*\z/
    email.match?(email_regex)
  end

end
