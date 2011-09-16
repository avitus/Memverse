class SessionsController < ApplicationController
  skip_before_filter :verify_authenticity_token, :only => :create
  
  def new
    redirect_to :controller => "memverses", :action => "index" and return if logged_in?
    session[:referrer] = params[:referrer]
    @blogposts = BlogPost.all(:limit => 2, :order => "created_at DESC", :conditions => ["is_complete = ?", true])
    @vsillumination = Popverse.find(:all, :order => "RAND()", :limit => 10)
    render :layout => false
  end
  
  def create
    logout_keeping_session! # Make sure to kill all session variable in ./lib/authenticated_system.rb
    password_authentication
    
    # Remove open_id_authentication to solve empty params hash problem in Rails 3.0.3
    # if using_open_id?
    #   open_id_authentication
    # else
    #   password_authentication
    # end
  end

  def destroy
    logout_killing_session!
    flash[:notice] = "You have been logged out."
    redirect_back_or_default(root_path)
  end
  
  # Remove open_id_authentication to solve empty params hash problem in Rails 3.0.3
  # def open_id_authentication
  #   authenticate_with_open_id do |result, identity_url|
  #     if result.successful? && self.current_user = User.find_by_identity_url(identity_url)
  #       successful_login
  #     else
  #       flash[:error] = result.message || "Sorry no user with that identity URL exists"
  #       @remember_me = params[:remember_me]
  #       render :action => :new
  #     end
  #   end
  # end

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
      redirect_to :action => :new  # This used to be a simple 'render' but we need to load blog posts on main page
    end
  end
  
  def successful_login
    new_cookie_flag = (params[:remember_me] == "1")
    handle_remember_cookie! new_cookie_flag
    redirect_back_or_default(home_path) # This loads the first page that the user sees after login
    flash[:notice] = "Logged in successfully."
    if !current_user.first_verse_today # current_user has no first_verse_today; therefore no verses due today
      flash[:notice] << " You do not have any verses to review today."
    end
  end

  def note_failed_signin
    if u = User.find_by_login(params[:login])
      if u.state == 'pending'
        flash[:error] = "Your account has not yet been activated. Please click on the link in the email you received from Memverse. It might be in your spam / junk mail folder."
      else
      	link = "<a href=\"#{forgot_password_path}\">Forgot password?</a>"      	
        flash[:error] = "Your password is incorrect. #{link}"
      end
    else
      link = "<a href=\"#{forgot_password_path}\">Forgot password?</a>" 
      flash[:error] = "Sorry. We couldn't find a user with user name '#{params[:login]}'. Please sign up first or check username. #{link}"
    end

    logger.warn "Failed login for '#{params[:login]}' from #{request.remote_ip} at #{Time.now.utc}"

  end
end
