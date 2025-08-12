class UserMailer < ActionMailer::Base

  default_url_options[:host] = "memverse.com"

  # default :from => "admin@memverse.com"
  default :from => '"Memverse" <admin@memverse.com>'

  # The keys of the hash passed to body become instance variables in the view.

  # ----------------------------------------------------------------------------------------------------------
  # Newsletter Email
  # ----------------------------------------------------------------------------------------------------------
  def newsletter_email(user)
    # @headers = {content_type => 'text/html'}
    setup_email(user)
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
    mail(
      :to => @email_with_name, 
      :subject => "Memverse Reminder",
      :tag => "progression-3",
      :message_stream => "broadcast"
    )
  end

  def progression_email_2(user)
    setup_email(user)
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
    mail(
      :to => @email_with_name, 
      :subject => "Welcome to Memverse!",
      :tag => "signup-notification",
      :message_stream => "outbound"
    )
  end

  def activation(user)
    setup_email(user)
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
    @url              = ApplicationSettings.config['url']
    
    # Use the Postmark unsubscribe method to add proper headers
    add_postmark_unsubscribe_link(user)
  end

end

