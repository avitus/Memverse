class SendReminders

  include Sidekiq::Worker

  sidekiq_options :retry => false

  def perform

    @emails_sent        = 0
    @throttle           = 50 # email send limit per recurrence period

    # Delete users who never activated
    User.pending.where('created_at < ?', 2.days.ago ).delete_all

    # Retrieve records for all users - find_each does it in batches of 1000
    User.find_each { |u|

      # Change reminder frequency (if necessary) to not be annoying
      u.update_reminder_freq

      if u.reminder_freq != "Never" and @emails_sent < @throttle

        # ==== Users who have added verses but are behind on memorizing ====
        if u.needs_reminder?

          # Check for invalid email field
          if u.email.blank?
            Rails.logger.info("** Error: Unable to email user with id: #{u.id}")
          
          else
            
            Rails.logger.info("* Sending progression email to #{u.name_or_login}. They are at progression level #{u.progression}.")

            # We need to send an email that is customized for every level of user progression
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

            @emails_sent += 1
            u.update_attribute(:last_reminder, Date.today)
          end

        end

      end # block for users who want reminders

    }

    Rails.logger.info(" *** Email reminder: Sent #{@emails_sent} reminder emails at #{Time.now}")

  end

end
