class UserMailer < ActionMailer::Base
  
# The keys of the hash passed to body become instance variables in the view.
  
  def signup_notification(user)
    @headers = {content_type => 'text/html'}
    setup_email(user)
    @subject = 'Please activate your Memverse account'
    @body[:url] = "#{APP_CONFIG[:site_url]}/activate/#{user.activation_code}"
  end
  
  def activation(user)
    setup_email(user)
    @subject << 'Your account has been activated!'
    @body[:url] = APP_CONFIG[:site_url]
  end
  
  def encourage_new_user_email(user)
    @headers = {content_type => 'text/html'}
    setup_email(user)
    @subject << 'Welcome to Memverse'
    @body[:url] = APP_CONFIG[:site_url]   
  end
  
  def newsletter_email(user)
    @headers = {content_type => 'text/html'}
    setup_email(user)
    @subject << 'Memverse Newsletter - April 2009'
    @body[:url] = APP_CONFIG[:site_url]   
  end  
  
  def reminder_email(user)
    @headers = {content_type => 'text/html'}
    setup_email(user)
    @from = APP_CONFIG[:admin_email]    
    @subject << 'Reminder'
    @body[:url]   = APP_CONFIG[:site_url]
    @body[:verse] = user.random_verse.verse
  end    

  def reminder_email_for_inactive(user)
    @headers = {content_type => 'text/html'}
    setup_email(user)
    @from = APP_CONFIG[:admin_email]    
    @subject << 'Reminder'
    @body[:url]   = APP_CONFIG[:site_url]
  end    
    
  protected
  
  def setup_email(user)
    @recipients             = "#{user.email}"
    @from                   = APP_CONFIG[:admin_email]
    @subject                = "#{APP_CONFIG[:site_name]} "
    @sent_on                = Time.now
    @body[:user]            = user
    @body[:unsubscribe_url] = "#{APP_CONFIG[:site_url]}/unsubscribe/#{user.email}"   
  end
end
