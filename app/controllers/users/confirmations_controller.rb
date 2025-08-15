class Users::ConfirmationsController < Devise::ConfirmationsController
  # Override show to send activation notification after confirmation
  def show
    self.resource = resource_class.confirm_by_token(params[:confirmation_token])
    yield resource if block_given?

    if resource.errors.empty?
      set_flash_message!(:notice, :confirmed)
      
      # Send activation notification after successful confirmation
      if resource.respond_to?(:send_activation_notification)
        resource.send(:send_activation_notification)
      end
      
      respond_with_navigational(resource){ redirect_to after_confirmation_path_for(resource_name, resource) }
    else
      respond_with_navigational(resource.errors, status: :unprocessable_entity){ render :new }
    end
  end
end