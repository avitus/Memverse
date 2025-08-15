# Test helper for email functionality
# 
# This helper is no longer needed since the current implementation uses
# Postmark's native :tag and :message_stream parameters in the mail() method.
# 
# The functionality is now handled directly by the :tag and :message_stream
# parameters in UserMailer and AdminMailer classes.

module PostmarkTestHelper
  # This module is kept for backward compatibility but is no longer used
  # since the mailers now use native Postmark parameters directly
  
  def self.setup_postmark_for_tests
    # No setup needed with current Postmark implementation
  end
  
  def self.reset
    # No reset needed with current implementation
  end
end