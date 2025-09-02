# frozen_string_literal: true

# Configure Postmark message streams for different email types
# 
# Available streams:
# - 'outbound': Transactional emails (default)
# - 'broadcast': Bulk/marketing emails  
# - 'reminder': Reminder emails (custom stream)
# - 'forum': Forum notification emails (custom stream)

Rails.application.config.to_prepare do
  # Override Thredded mailers to use the 'forum' message stream
  if defined?(Thredded::BaseMailer)
    Thredded::BaseMailer.class_eval do
      # Override the mail method to add forum stream
      def mail(headers = {}, &block)
        # Add forum stream configuration
        headers[:message_stream] = 'forum-stream'
        headers[:tag] ||= 'forum-notification'
        
        # Add test environment headers for compatibility
        if Rails.env.test?
          self.headers['X-PM-Message-Stream'] = 'forum-stream'
          self.headers['X-PM-Tag'] = headers[:tag]
        end
        
        super(headers, &block)
      end
    end
  end
end