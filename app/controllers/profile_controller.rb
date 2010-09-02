class ProfileController < ApplicationController
 
  before_filter :login_required, :except => :unsubscribe
 
  # ----------------------------------------------------------------------------------------------------------
  # Show Church Members
  # ----------------------------------------------------------------------------------------------------------  
  def show_church
    
    @page_title = "Church Members"
    @tab        = "profile"

    if params[:church]
      @church         = Church.find(params[:church])
      @users          = @church.users
    elsif current_user.church
      @church         = current_user.church
      @users          = @church.users
    else
      flash[:notice]  = "You have not yet selected a church or organization to belong to. Please update your profile."
      redirect_to update_profile_path
    end

  end   

 
  # ----------------------------------------------------------------------------------------------------------
  # Unsubscribe user from email
  # ----------------------------------------------------------------------------------------------------------   
  def unsubscribe
    email_address = params[:email][0]
    
    u = User.find_by_email(email_address)
    
    if u
      if u.unsubscribe
        flash[:notice] = "You have been unsubscribed from all Memverse emails."
        logger.info("*** User #{u.login} unsubscribed from all emails")
      else
        flash[:notice] = "Sorry. We failed to save the changes to your email preferences."
        logger.error("*** Couldn't execute email unsubscribe request for #{email_address}")
      end
    else
      flash[:notice] = "We couldn't find a user with that email address"
      logger.warn("*** Couldn't find user with email address #{email_address}")
    end
    
  end


  # ----------------------------------------------------------------------------------------------------------
  # Update Profile
  # Input: params[:user]
  # Output: JSON object
  # ---------------------------------------------------------------------------------------------------------- 
  def update_profile
    
    # -- Tabs and Title --
    @tab = "profile"    
    @page_title = "Memverse : Update Profile"
    
    # -- Display Form --
    @user           = User.find(current_user)
    @user_country   = @user.country ?         @user.country.printable_name  : ""
    @user_church    = @user.church ?          @user.church.name             : ""
    @user_state     = @user.american_state ?  @user.american_state.name     : ""
    
    # -- Process Form --
    if request.put? # For some reason this is a 'put' not a 'post'
      if @user.update_profile(params[:user])
        flash[:notice] = "Profile successfully updated. "
        spawn do
          q = Quest.find_by_url(url_for(:action => 'update_profile', :controller => 'profile', :only_path => false))
          q.check_quest_off(current_user)
          flash.keep[:notice] = "You have completed the task: #{q.task}"
        end        
        redirect_to home_path
      else
        render :action => update_profile
      end
    end
    
    
  end # method: update_profile

  # ----------------------------------------------------------------------------------------------------------
  # Autocomplete for Country Names
  # Input: params[:query]
  # Output: JSON object
  # ----------------------------------------------------------------------------------------------------------   
  def country_autocomplete
    
    # Return country list in JSON format
    #    {
    #       query:'Li',
    #       suggestions:['Liberia','Libyan Arab Jamahiriya','Liechtenstein','Lithuania'],
    #       data:['LR','LY','LI','LT']
    #    }

    @suggestions = Array.new

    query         = params[:query]
    query_length  = query.length
    
    all_countries = Country.find(:all, :select => 'printable_name')
    
    all_countries.each { |country|
      name = country.printable_name
      if name[0...query_length].downcase == query.downcase
        @suggestions << name
      end
    }
    
    render :json => {:query => query, :suggestions => @suggestions }.to_json

  end

  # ----------------------------------------------------------------------------------------------------------
  # Autcomplete for State Names
  # Input: params[:query]
  # Output: JSON object
  # ----------------------------------------------------------------------------------------------------------   
  def state_autocomplete
    
    # Return state list in JSON format
    #    {
    #       query:'Mi',
    #       suggestions:['Minnesota','Michigan', etc],
    #       data:[ ? ]
    #    }

    @suggestions = Array.new

    query         = params[:query]
    query_length  = query.length
    
    all_states = AmericanState.find(:all, :select => 'name')
    
    all_states.each { |state|
      name = state.name
      if name[0...query_length].downcase == query.downcase
        @suggestions << name
      end
    }
    
    render :json => {:query => query, :suggestions => @suggestions }.to_json

  end


  # ----------------------------------------------------------------------------------------------------------
  # Autcomplete for Church Names
  # Input: params[:query]
  # Output: JSON object
  # ----------------------------------------------------------------------------------------------------------   
  def church_autocomplete
    # Return country list in JSON format
    #    {
    #       query:'Li',
    #       suggestions:['Liberia','Libyan Arab Jamahiriya','Liechtenstein','Lithuania'],
    #       data:['LR','LY','LI','LT']
    #    }

    @suggestions = Array.new

    query         = params[:query]
    query_length  = query.length
    
    all_churches = Church.find(:all, :select => 'name')
    
    all_churches.each { |church|
      name = church.name
      if name[0...query_length].downcase == query.downcase
        @suggestions << name
      end
    }
    
    render :json => {:query => query, :suggestions => @suggestions }.to_json

  end

  # ----------------------------------------------------------------------------------------------------------
  # Set the person who referred you
  # ----------------------------------------------------------------------------------------------------------    
  def set_as_referrer
    referrer = User.find(params[:id])
    
    if referrer == current_user
      flash[:notice] = "You cannot refer yourself!"
    elsif referrer.referred_by == current_user.id
      flash[:notice] = "You cannot be referred by a person you referred."
    else
      current_user.referred_by = referrer.id
      current_user.save
      flash[:notice] = "You have set your referrer as: #{referrer.name_or_login}"
    end
  
    redirect_to referrals_path(current_user)
  end

  # ----------------------------------------------------------------------------------------------------------
  # Referral page
  # ----------------------------------------------------------------------------------------------------------   
  def referrals
    @user = User.find(params[:id]) || current_user
    
    @referrer  = User.find(@user.referred_by) if @user.referred_by
    
    # Clean up users who have referred themselves
    # TODO: This section can be removed since we now prevent this from happening
    if @user == @referrer
      flash[:notice] = "You can't refer yourself!"
      @user.referred_by = nil
      @user.save
      @referrer = nil
    end
    
    @users     = User.find(:all, :conditions => {:referred_by => @user.id})
    
  end

  # ----------------------------------------------------------------------------------------------------------
  # Interactive User Search (To Find Referrer)
  # ----------------------------------------------------------------------------------------------------------  
  def search_user
    
    search_param = params[:search_param]
    
    # TODO: Is there a better way to do this search?
    
    @user_list =  User.find(:all, :conditions => {:login => search_param }, :limit => 5)
    
    if @user_list.empty?
      @user_list = User.find(:all, :conditions => {:email => search_param }, :limit => 5)
    end
  
    if @user_list.empty?
      @user_list = User.find(:all, :conditions => {:name  => search_param }, :limit => 5)
    end 
    
    render :partial => 'search_user', :layout=>false 
  end 


  def set_referrer
    @user_list = Array.new  
  end 

end # Class
