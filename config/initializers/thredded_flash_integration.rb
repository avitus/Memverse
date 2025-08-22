# This initializer integrates Thredded's flash messages with the main application's flash system
# It ensures that Thredded flash messages use the same keys as the main application

Rails.application.config.to_prepare do
  if defined?(Thredded::ApplicationController)
    Thredded::ApplicationController.class_eval do
      # Override flash usage to match main application conventions
      # The main app uses :notice for success messages
      
      # Hook into redirect methods to convert flash keys
      def redirect_to(options = {}, response_options = {})
        # Convert Thredded's :success to :notice for consistency
        if flash[:success]
          flash[:notice] = flash.delete(:success)
        end
        super
      end
      
      # Also handle render calls that might set flash.now
      def render(*args)
        # Convert flash.now[:success] to flash.now[:notice]
        if flash.now[:success]
          flash.now[:notice] = flash.now.delete(:success)
        end
        super
      end
    end
  end
end