class SessionsController < ApplicationController
  skip_before_filter :verify_authenticity_token, :only => :create
  
  def new
    session[:referrer] = params[:referrer]
  end

  def create
    logout_keeping_session! # Make sure to kill all session variable in ./lib/authenticated_system.rb
    if using_open_id?
      open_id_authentication
    else
      password_authentication
    end
  end

  def destroy
    logout_killing_session!
    flash[:notice] = "You have been logged out."
    redirect_back_or_default(root_path)
  end
  
  def open_id_authentication
    authenticate_with_open_id do |result, identity_url|
      if result.successful? && self.current_user = User.find_by_identity_url(identity_url)
        successful_login
      else
        flash[:error] = result.message || "Sorry no user with that identity URL exists"
        @remember_me = params[:remember_me]
        render :action => :new
      end
    end
  end

  protected
  
  def password_authentication
    user = User.authenticate(params[:login], params[:password])
    if user
      self.current_user = user
      successful_login
    else
      note_failed_signin
      @login = params[:login]
      @remember_me = params[:remember_me]
      render :action => :new
    end
  end
  
  def successful_login
    new_cookie_flag = (params[:remember_me] == "1")
    handle_remember_cookie! new_cookie_flag
    redirect_back_or_default(home_path) # This loads the first page that the user sees after login
    flash[:notice] = "Logged in successfully"
  end

  def note_failed_signin
    if u = User.find_by_login(params[:login])
      if u.state == 'pending'
        flash[:error] = "Your account has not yet been activated. Please click on the link in the email you received from Memverse. It might be in your spam / junk mail folder."
      else
        flash[:error] = "Your password is incorrect."
      end
    else
      flash[:error] = "Sorry. We couldn't find a user with user name '#{params[:login]}'. Please sign up first or check username."
    end

    logger.warn "Failed login for '#{params[:login]}' from #{request.remote_ip} at #{Time.now.utc}"

  end
end
