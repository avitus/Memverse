class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def windowslive

      @user = User.find_for_windowslive_oauth2( request.env["omniauth.auth"], current_user )

      if @user.persisted?
        flash[:notice] = I18n.t "devise.omniauth_callbacks.success", :kind => "WindowsLive"
        sign_in_and_redirect @user, :event => :authentication
      else
        session["devise.windowslive_data"] = request.env["omniauth.auth"]
        redirect_to new_user_registration_path
      end

  end
end