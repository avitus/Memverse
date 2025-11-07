# frozen_string_literal: true

# Fix for production 500 error when moderating posts
# The issue is likely CSRF token verification failing

Rails.application.config.after_initialize do
  if defined?(Thredded::ApplicationController)
    Rails.logger.info "[CSRF FIX] Patching Thredded::ApplicationController"

    # Thredded controllers inherit from Thredded::ApplicationController
    Thredded::ApplicationController.class_eval do
      # Log CSRF token failures instead of raising
      rescue_from ActionController::InvalidAuthenticityToken do |exception|
        Rails.logger.error "[CSRF FIX] Invalid authenticity token for #{request.path}"
        Rails.logger.error "[CSRF FIX] Request method: #{request.method}"
        Rails.logger.error "[CSRF FIX] User: #{current_user&.id || 'anonymous'}"
        Rails.logger.error "[CSRF FIX] Headers: #{request.headers.to_h.select { |k, v| k.start_with?('HTTP_') }.inspect}"

        # For moderation actions, try to handle gracefully
        if request.path == '/forum/admin/moderation' && request.post?
          flash[:error] = "Security token expired. Please try again."
          redirect_back fallback_location: '/forum/admin/moderation'
        else
          # Re-raise for other actions
          raise
        end
      end
    end

    Rails.logger.info "[CSRF FIX] Patch applied successfully"
  else
    Rails.logger.warn "[CSRF FIX] Thredded::ApplicationController not found"
  end

  # Also patch ModerationController directly
  if defined?(Thredded::ModerationController)
    Rails.logger.info "[CSRF FIX] Patching Thredded::ModerationController directly"

    Thredded::ModerationController.class_eval do
      # Add specific handling for moderation actions
      before_action :log_csrf_token, only: [:moderate_post]

      private

      def log_csrf_token
        Rails.logger.info "[CSRF FIX] moderate_post - CSRF Token present: #{request.headers['X-CSRF-Token'].present?}"
        Rails.logger.info "[CSRF FIX] moderate_post - Authenticity token in params: #{params[:authenticity_token].present?}"
      end

      # Override verify_authenticity_token for debugging
      def verify_authenticity_token
        Rails.logger.info "[CSRF FIX] verify_authenticity_token called for #{action_name}"
        super
      rescue ActionController::InvalidAuthenticityToken => e
        Rails.logger.error "[CSRF FIX] CSRF verification failed for #{action_name}"
        Rails.logger.error "[CSRF FIX] Exception: #{e.message}"
        raise
      end
    end

    Rails.logger.info "[CSRF FIX] ModerationController patch applied"
  end
end

# Also add a general handler at the application level
ApplicationController.class_eval do
  rescue_from ActionController::InvalidAuthenticityToken do |exception|
    Rails.logger.error "[APP CSRF FIX] Invalid authenticity token"
    Rails.logger.error "[APP CSRF FIX] Path: #{request.path}"
    Rails.logger.error "[APP CSRF FIX] Method: #{request.method}"

    # Log but re-raise to maintain default behavior
    raise
  end
end

Rails.logger.info "[CSRF FIX] All CSRF fixes loaded"