class UserMailer < ActionMailer::Base

  # UserMailer will inherit default URL options from ActionMailer::Base
  # which are set in config/initializers/action_mailer.rb

  # default :from => "admin@memverse.com"
  default :from => '"Memverse" <admin@memverse.com>'

  # The keys of the hash passed to body become instance variables in the view.

  # ----------------------------------------------------------------------------------------------------------
  # Newsletter Email
  # ----------------------------------------------------------------------------------------------------------
  def newsletter_email(user)
    # @headers = {content_type => 'text/html'}
    setup_email(user)
    
    # Set Postmark headers manually for test environments
    if Rails.env.test?
      headers['X-PM-Tag'] = 'newsletter'
      headers['X-PM-Message-Stream'] = 'broadcast'
    end
    
    mail(
      :to => @email_with_name, 
      :subject => "Memverse Newsletter",
      :tag => "newsletter",
      :message_stream => "broadcast"
    )
  end

  # ----------------------------------------------------------------------------------------------------------
  # User Progression Emails
  # ----------------------------------------------------------------------------------------------------------
  def progression_email_9(user)
    setup_email(user)
    @verse = user.random_verse.verse
    
    # Set Postmark headers manually for test environments
    if Rails.env.test?
      headers['X-PM-Tag'] = 'progression-9'
      headers['X-PM-Message-Stream'] = 'broadcast'
    end
    
    mail(
      :to => @email_with_name, 
      :subject => "Memverse Reminder",
      :tag => "progression-9",
      :message_stream => "broadcast"
    )
  end


  def progression_email_8(user)
    setup_email(user)
    @verse = user.random_verse.verse
    
    # Set Postmark headers manually for test environments
    if Rails.env.test?
      headers['X-PM-Tag'] = 'progression-8'
      headers['X-PM-Message-Stream'] = 'broadcast'
    end
    
    mail(
      :to => @email_with_name, 
      :subject => "Memverse Reminder",
      :tag => "progression-8",
      :message_stream => "broadcast"
    )
  end


  def progression_email_7(user)
    setup_email(user)
    @verse = user.random_verse.verse
    
    # Set Postmark headers manually for test environments
    if Rails.env.test?
      headers['X-PM-Tag'] = 'progression-7'
      headers['X-PM-Message-Stream'] = 'broadcast'
    end
    
    mail(
      :to => @email_with_name, 
      :subject => "Memverse Reminder",
      :tag => "progression-7",
      :message_stream => "broadcast"
    )
  end


  def progression_email_6(user)
    setup_email(user)
    @verse = user.random_verse.verse
    
    # Set Postmark headers manually for test environments
    if Rails.env.test?
      headers['X-PM-Tag'] = 'progression-6'
      headers['X-PM-Message-Stream'] = 'broadcast'
    end
    
    mail(
      :to => @email_with_name, 
      :subject => "Memverse Reminder",
      :tag => "progression-6",
      :message_stream => "broadcast"
    )
  end

  def progression_email_5(user)
    setup_email(user)
    @verse = user.random_verse.verse
    
    # Set Postmark headers manually for test environments
    if Rails.env.test?
      headers['X-PM-Tag'] = 'progression-5'
      headers['X-PM-Message-Stream'] = 'broadcast'
    end
    
    mail(
      :to => @email_with_name, 
      :subject => "Memverse Reminder",
      :tag => "progression-5",
      :message_stream => "broadcast"
    )
  end

  def progression_email_4(user)
    setup_email(user)
    @verse = user.random_verse.verse
    
    # Set Postmark headers manually for test environments
    if Rails.env.test?
      headers['X-PM-Tag'] = 'progression-4'
      headers['X-PM-Message-Stream'] = 'broadcast'
    end
    
    mail(
      :to => @email_with_name, 
      :subject => "Memverse Reminder",
      :tag => "progression-4",
      :message_stream => "broadcast"
    )
  end

  def progression_email_3(user)
    setup_email(user)
    @verse = user.random_verse.verse
    
    # Set Postmark headers manually for test environments
    if Rails.env.test?
      headers['X-PM-Tag'] = 'progression-3'
      headers['X-PM-Message-Stream'] = 'broadcast'
    end
    
    mail(
      :to => @email_with_name, 
      :subject => "Memverse Reminder",
      :tag => "progression-3",
      :message_stream => "broadcast"
    )
  end

  def progression_email_2(user)
    setup_email(user)
    
    # Set Postmark headers manually for test environments
    if Rails.env.test?
      headers['X-PM-Tag'] = 'progression-2'
      headers['X-PM-Message-Stream'] = 'broadcast'
    end
    
    mail(
      :to => @email_with_name, 
      :subject => "Memverse Reminder",
      :tag => "progression-2",
      :message_stream => "broadcast"
    )
  end

  # ----------------------------------------------------------------------------------------------------------
  # User Registration and Activation Emails (replacing UserObserver functionality)
  # ----------------------------------------------------------------------------------------------------------
  def signup_notification(user)
    setup_email(user)
    
    # Set Postmark headers manually for test environments
    if Rails.env.test?
      headers['X-PM-Tag'] = 'signup-notification'
      headers['X-PM-Message-Stream'] = 'outbound'
    end
    
    mail(
      :to => @email_with_name, 
      :subject => "Welcome to Memverse!",
      :tag => "signup-notification",
      :message_stream => "outbound"
    )
  end

  def activation(user)
    setup_email(user)
    
    # Set Postmark headers manually for test environments
    if Rails.env.test? || ActionMailer::Base.delivery_method == :cache
      headers['X-PM-Tag'] = 'account-activation'
      headers['X-PM-Message-Stream'] = 'outbound'
    end
    
    mail(
      :to => @email_with_name, 
      :subject => "Your Memverse account has been activated!",
      :tag => "account-activation",
      :message_stream => "outbound"
    )
  end

  # ----------------------------------------------------------------------------------------------------------
  # Protected
  # ----------------------------------------------------------------------------------------------------------
  protected

  def setup_email(user)
    @subject          = "Memverse"
    @sent_on          = Time.now
    @user		          = user
    @email_with_name  = "#{@user.name} <#{@user.email}>"
    @url              = ApplicationSettings.config['url'] || "https://memverse.com"
    base_url          = ApplicationSettings.config['url'] || "https://memverse.com"
    @unsubscribe_url  = "#{base_url}/unsubscribe/#{user.email}"
    
    # Use the Postmark unsubscribe method to add proper headers
    add_postmark_unsubscribe_link(user)
  end

  private

  def add_postmark_unsubscribe_link(user)
    # Add List-Unsubscribe headers for Postmark compliance
    return if user.nil? || user.email.blank?
    
    base_url = ApplicationSettings.config['url'] || "https://memverse.com"
    unsubscribe_url = "#{base_url}/unsubscribe/#{user.email}"
    headers['List-Unsubscribe'] = "<#{unsubscribe_url}>"
    headers['List-Unsubscribe-Post'] = "List-Unsubscribe=One-Click"
  end

end

