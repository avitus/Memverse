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
    @throttle           = 2  # email send limit per recurrence period

    # Delete users who never activated
    User.pending.where('created_at < ?', 2.days.ago ).delete_all

    # Retrieve records for all users ordered by newest first
    # Process newest users first to prioritize recently registered users
    # Note: Using in_batches with order instead of find_each which ignores order
    User.order(created_at: :desc).in_batches(of: 100) do |batch|
      # Apply ordering to the batch before iterating to ensure order is preserved
      batch.order(created_at: :desc).each do |u|

      # Change reminder frequency (if necessary) to not be annoying
      u.update_reminder_freq

      if u.reminder_freq != "Never" and @emails_sent < @throttle

        # ==== Users who have added verses but are behind on memorizing ====
        if u.needs_reminder?

          # Check for invalid email field
          if !valid_email?(u.email)
            if u.email.blank?
              Rails.logger.info("** Error: Unable to email user with id: #{u.id} - blank email address")
            else
              Rails.logger.warn("** Error: Unable to email user with id: #{u.id} - invalid email format: '#{u.email}'")
            end
          
          else
            
            Rails.logger.info("* Sending progression email to #{u.name_or_login}. They are at progression level #{u.progression}.")

            begin
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
              
            rescue Postmark::InvalidEmailRequestError => e
              # Detailed logging for Postmark email errors to help identify problematic users
              Rails.logger.error("** POSTMARK ERROR for User #{u.id}:")
              Rails.logger.error("   User ID: #{u.id}")
              Rails.logger.error("   User name: '#{u.name}'")
              Rails.logger.error("   User login: '#{u.login}'")
              Rails.logger.error("   User email: '#{u.email}'")
              Rails.logger.error("   Name or login: '#{u.name_or_login}'")
              Rails.logger.error("   Progression level: #{u.progression}")
              Rails.logger.error("   Error message: #{e.message}")
              Rails.logger.error("   Email format attempted: '#{u.name} <#{u.email}>'")
              # Log additional debugging info
              Rails.logger.error("   Name bytes: #{u.name.bytes.inspect}") if u.name
              Rails.logger.error("   Name encoding: #{u.name.encoding}") if u.name
              # Continue processing other users even if one email fails
            rescue => e
              Rails.logger.error("** Error: Failed to send progression email to user #{u.id} (#{u.email}): #{e.class} - #{e.message}")
              # Continue processing other users even if one email fails
            end
          end

        end

      end # block for users who want reminders

      end # batch.each
    end # in_batches

    Rails.logger.info(" *** Email reminder: Sent #{@emails_sent} reminder emails at #{Time.now}")

  end

  private

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
