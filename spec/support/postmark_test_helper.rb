# Test helper for email functionality
# 
# This helper is no longer needed since the current implementation uses
# X-MC-Tags headers instead of Postmark tag/message_stream attributes.
# 
# The functionality is now handled directly by ActionMailer headers in
# the UserMailer class.

module PostmarkTestHelper
  # This module is kept for backward compatibility but is no longer used
  # since the mailers now use X-MC-Tags headers directly
  
  def self.setup_postmark_for_tests
    # No setup needed with current X-MC-Tags implementation
  end
  
  def self.reset
    # No reset needed with current implementation
  end
end