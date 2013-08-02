class UserMailer < ActionMailer::Base

  default_url_options[:host] = "memverse.com"

  default :from => "admin@memverse.com"

  # The keys of the hash passed to body become instance variables in the view.

  # Can probably delete this - now handled by Devise
  # def signup_notification(user)
  	# setup_email(user)
  	# @url = "#{APP_CONFIG[:site_url]}/activate/#{user.activation_code}"
  	# mail(:to => user.email, :subject => "Please activate your Memverse account")
  # end

  # def activation(user)
    # setup_email(user)
    # mail(:to => user.email, :subject => "Your Memverse account is activated")
  # end

  def encourage_new_user_email(user)
    # @headers = {content_type => 'text/html'}
    setup_email(user)
    headers['X-MC-Tags'] = "reminder, new_user"
    mail(:to => @email_with_name, :subject => "Welcome to Memverse")
  end

  def newsletter_email(user)
    # @headers = {content_type => 'text/html'}
    setup_email(user)
    headers['X-MC-Tags'] = "newsletter"
    mail(:to => @email_with_name, :subject => "Memverse Newsletter")
  end

  def reminder_email(user)
    # @headers = {content_type => 'text/html'}
    setup_email(user)
    headers['X-MC-Tags'] = "reminder"
    @verse = user.random_verse.verse
    mail(:to => @email_with_name, :subject => "Memverse Reminder")
  end

  def reminder_email_for_inactive(user)
    # @headers = {content_type => 'text/html'}
    setup_email(user)
    headers['X-MC-Tags'] = "reminder, inactive"
    mail(:to => @email_with_name, :subject => "Memverse Reminder")
  end

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

