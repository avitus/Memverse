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
    headers['X-MC-Tags'] = "newsletter"
    mail(:to => @email_with_name, :subject => "Memverse Newsletter")
  end

  # ----------------------------------------------------------------------------------------------------------
  # User Progression Emails
  # ----------------------------------------------------------------------------------------------------------
  def progression_email_9(user)
    setup_email(user)
    headers['X-MC-Tags'] = "progression-9"
    @verse = user.random_verse.verse
    mail(:to => @email_with_name, :subject => "Memverse Reminder")
  end


  def progression_email_8(user)
    setup_email(user)
    headers['X-MC-Tags'] = "progression-8"
    @verse = user.random_verse.verse
    mail(:to => @email_with_name, :subject => "Memverse Reminder")
  end


  def progression_email_7(user)
    setup_email(user)
    headers['X-MC-Tags'] = "progression-7"
    @verse = user.random_verse.verse
    mail(:to => @email_with_name, :subject => "Memverse Reminder")
  end


  def progression_email_6(user)
    setup_email(user)
    headers['X-MC-Tags'] = "progression-6"
    @verse = user.random_verse.verse
    mail(:to => @email_with_name, :subject => "Memverse Reminder")
  end

  def progression_email_5(user)
    setup_email(user)
    headers['X-MC-Tags'] = "progression-5"
    @verse = user.random_verse.verse
    mail(:to => @email_with_name, :subject => "Memverse Reminder")
  end

  def progression_email_4(user)
    setup_email(user)
    headers['X-MC-Tags'] = "progression-4"
    @verse = user.random_verse.verse
    mail(:to => @email_with_name, :subject => "Memverse Reminder")
  end

  def progression_email_3(user)
    setup_email(user)
    headers['X-MC-Tags'] = "progression-3"
    @verse = user.random_verse.verse
    mail(:to => @email_with_name, :subject => "Memverse Reminder")
  end

  def progression_email_2(user)
    setup_email(user)
    headers['X-MC-Tags'] = "progression-2"
    mail(:to => @email_with_name, :subject => "Memverse Reminder")
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
    @unsubscribe_url	= "#{ApplicationSettings.config['url']}/unsubscribe/#{user.email}"
  end

end

