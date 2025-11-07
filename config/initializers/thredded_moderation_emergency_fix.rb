# frozen_string_literal: true

# EMERGENCY FIX for production moderation 500 error
# This is a minimal intervention to log what's happening

Rails.application.config.after_initialize do
  if defined?(Thredded::ModerationController)
    Rails.logger.info "[EMERGENCY FIX] Patching Thredded::ModerationController"

    Thredded::ModerationController.class_eval do
      # Prepend a module to intercept the action
      module EmergencyLogging
        def moderate_post
          Rails.logger.info "[EMERGENCY FIX] moderate_post called"
          Rails.logger.info "[EMERGENCY FIX] params class: #{params.class}"
          Rails.logger.info "[EMERGENCY FIX] params keys: #{params.keys.inspect}"
          Rails.logger.info "[EMERGENCY FIX] params: #{params.to_unsafe_h.inspect}" rescue Rails.logger.info "[EMERGENCY FIX] Could not inspect params"

          begin
            super
          rescue => e
            Rails.logger.error "[EMERGENCY FIX] Error in moderate_post: #{e.class} - #{e.message}"
            Rails.logger.error e.backtrace.first(15).join("\n")

            # Try to return a meaningful error response
            respond_to do |format|
              format.html {
                flash[:error] = "An error occurred while moderating the post. Please try again."
                redirect_back fallback_location: pending_moderation_path
              }
              format.json { render json: { error: e.message }, status: :internal_server_error }
            end
          end
        end
      end

      prepend EmergencyLogging
    end

    Rails.logger.info "[EMERGENCY FIX] Patch applied successfully"
  else
    Rails.logger.error "[EMERGENCY FIX] Thredded::ModerationController not found!"
  end
end