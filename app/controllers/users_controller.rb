class UsersController < ApplicationController
  skip_before_filter :verify_authenticity_token, :only => :create
  before_filter :authenticate_user!, :only => :show
  
  add_breadcrumb "Home", :root_path
  
  def new
    @user = User.new
  end

  def show
    @tab = "profile"
    @sub = "dash" 	
    @user = User.find(params[:id])
    
    if @user == current_user
      add_breadcrumb I18n.t('menu.profile'), :current_user
      # Check for completed tasks    
      if quests = @user.check_for_completed_quests
        flash.now[:notice] = "Great. You have completed the following task: #{quests.length}"
      end
      
      # Has user leveled up?
      if @user.check_for_level_up
        flash.now[:notice] = "Congratulations!! You have reached level #{@user.level}."
        if @user.level >= 20
          Tweet.create(:news => "#{@user.name_or_login} has reached level #{@user.level}", :user_id => @user.id, :importance => 1)
        elsif @user.level >= 5
          Tweet.create(:news => "#{@user.name_or_login} has reached level #{@user.level}", :user_id => @user.id, :importance => 3)
        else
          Tweet.create(:news => "#{@user.name_or_login} has reached level #{@user.level}", :user_id => @user.id, :importance => 5)
        end          
      end    
      
      @current_user_quests      = @user.current_uncompleted_quests
      @current_completed_quests = @user.current_completed_quests
    
    else # This is not current user
      add_breadcrumb I18n.t( :user_profile, :scope => 'page_titles', :name => @user.name_or_login), @user_path    
    end
    
  end 
 
  def create
    logout_keeping_session!
    create_new_user(params[:user])
    # if using_open_id?
    #   authenticate_with_open_id(params[:openid_url], :return_to => open_id_create_url, 
    #     :required => [:nickname, :email]) do |result, identity_url, registration|
    #     if result.successful?
    #       create_new_user(:identity_url => identity_url, :login => registration['nickname'], :email => registration['email'])
    #     else
    #       failed_creation(result.message || "Sorry, something went wrong")
    #     end
    #   end
    # else
    #   create_new_user(params[:user])
    # end
  end
  
  
  # TODO: no longer needed now that we're using Devise (?)
  def activate
    logout_keeping_session!
    user = User.find_by_activation_code(params[:activation_code]) unless params[:activation_code].blank?
    case
    when (!params[:activation_code].blank?) && user && !user.active?
      user.activate!
      flash[:notice] = "Signup complete! Please sign in to continue."
      redirect_to new_user_session_path
    when params[:activation_code].blank?
      flash[:error] = "The activation code was missing.  Please follow the URL from your email."
      redirect_back_or_default(root_path)
    else 
      flash[:error]  = "We couldn't find a user with that activation code -- check your email? Or maybe you've already activated -- try signing in."
      redirect_back_or_default(root_path)
    end
  end

  def reset_schedule
  	due_today = current_user.reset_memorization_schedule
  	render :json => {:due_verses => due_today }
  end
  
  protected
  
  def create_new_user(attributes)
    @user = User.new(attributes)
    if @user && @user.valid?
      if @user.not_using_openid?
        @user.register!
      else
        @user.register_openid!
      end
    end
    
    if @user.errors.empty?
      successful_creation(@user)
    else
      failed_creation
    end
  end
  
  def successful_creation(user)
    redirect_back_or_default(root_path)
    add_referrer(user, session[:referrer]) if session[:referrer]   
    flash[:notice] = "Thanks for signing up!"
    flash[:notice] << " We're sending you an email with your activation code. Please make sure to check your spam folder if you don't receive the activation email." if @user.not_using_openid?
    flash[:notice] << " You can now login with your OpenID." unless @user.not_using_openid?
  end
  
  def failed_creation(message = 'Sorry, there was an error creating your account')
    flash[:error] = message
    render :action => :new
  end
   
  def add_referrer(user, referrer_login)
    referrer = User.find_by_login(session[:referrer])
    user.referred_by = referrer.id
    user.save
  end  	
   
end
