# Postmark configuration for email delivery
# 
# This file configures Postmark-specific settings for email delivery.
# Postmark is used for reliable transactional and broadcast email delivery.

# Configure ActionMailer to use Postmark-specific features
ActionMailer::Base.class_eval do
  # Add method for managing unsubscribe links
  def add_postmark_unsubscribe_link(user)
    if user && user.email.present?
      unsubscribe_url = "#{ApplicationSettings.config['url']}/unsubscribe/#{user.email}"
      
      # Set custom header for email clients
      headers['List-Unsubscribe'] = "<#{unsubscribe_url}>"
      headers['List-Unsubscribe-Post'] = "List-Unsubscribe=One-Click"
      
      # Make unsubscribe URL available to email templates
      @unsubscribe_url = unsubscribe_url
    end
  end
end