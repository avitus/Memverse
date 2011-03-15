class UserMailer < ActionMailer::Base
  
  default_url_options[:host] = "example.com"
  
  default :from => "admin@memverse.com"
    
  # The keys of the hash passed to body become instance variables in the view.

  def signup_notification(user)
  	setup_email(user)
  	@url = "#{APP_CONFIG[:site_url]}/activate/#{user.activation_code}"
  	mail(:to => user.email, :subject => "Please activate your Memverse account")
  end

  def activation(user)
    setup_email(user)
    mail(:to => user.email, :subject => "Your Memverse account is activated")
  end
  
  def encourage_new_user_email(user)
    @headers = {content_type => 'text/html'}
    setup_email(user)
    mail(:to => user.email, :subject => "Welcome to Memverse")
  end
  
  def newsletter_email(user)
    @headers = {content_type => 'text/html'}
    setup_email(user)
    mail(:to => user.email, :subject => "Memverse Newsletter")
  end  
  
  def reminder_email(user)
    @headers = {content_type => 'text/html'}
    setup_email(user)
    @verse = user.random_verse.verse
    mail(:to => user.email, :subject => "Memverse Reminder")
  end    

  def reminder_email_for_inactive(user)
    @headers = {content_type => 'text/html'}
    setup_email(user)
    mail(:to => user.email, :subject => "Memverse Reminder")
  end    
 
  protected
  
  def setup_email(user)
    @subject            = "#{APP_CONFIG[:site_name]} "
    @sent_on            = Time.now
    @user		        = user
    @url				= APP_CONFIG[:site_url]
    @unsubscribe_url	= "#{APP_CONFIG[:site_url]}/unsubscribe/#{user.email}"   
  end   
      
end
