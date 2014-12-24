class SendReminders

  include Sidekiq::Worker
  include Sidetiq::Schedulable

  sidekiq_options :retry => true

  recurrence do
    hourly(1)
  end

  def perform
    @emails_sent        = 0
    @email_list         = Array.new
    @encourage_list     = Array.new
    @bounce_list        = Array.new

    @throttle           = 50 # email send limit per recurrence period

    # Delete users who never activated
    User.pending.where('created_at < ?', 2.days.ago ).delete_all

    # Retrieve records for all users - find_each does it in batches of 1000
    User.find_each { |r|
      # Change reminder frequency (if necessary) to not be annoying
      r.update_reminder_freq

      if r.reminder_freq != "Never" and @emails_sent < @throttle

        # ==== Users who have added verses but are behind on memorizing ====
        if r.needs_reminder?
          if r.email.nil?
            Rails.logger.info("** Error: Unable to email user with id: #{r.id}")
            @bounce_list << r
          else
            if r.is_inactive?
              # Reminder for inactive users
              Rails.logger.info("* Sending reminder email to #{r.name_or_login} - they've been inactive for two months")
              UserMailer.reminder_email_for_inactive(r).deliver
            else
              # Standard reminder email
              Rails.logger.info("* Sending reminder email to #{r.name_or_login}")
              UserMailer.reminder_email(r).deliver
            end
            @emails_sent += 1
            r.update_attribute(:last_reminder, Date.today)
            @email_list << r
          end
        end

        # ==== Users who have activated but haven't ever added a verse ====
        if r.needs_kick_in_pants?
          if r.email.nil?
            Rails.logger.info("** Error: Unable to email user with id: #{r.id}")
            @bounce_list << r
          else
            Rails.logger.info("* Sending kick in the pants to #{r.name_or_login}")
            UserMailer.encourage_new_user_email(r).deliver
            @emails_sent += 1
            r.last_reminder = Date.today
            r.save
            @encourage_list << r
          end
        end

      end # block for users who want reminders

    }

    Rails.logger.info(" *** Email reminder: Sent #{@emails_sent} reminder emails at #{Time.now}")
  end

end
