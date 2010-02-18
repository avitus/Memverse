class ProfileController < ApplicationController
 
  before_filter :login_required 
 
  # ----------------------------------------------------------------------------------------------------------
  # Show Church Members
  # ----------------------------------------------------------------------------------------------------------  
  def show_church
    
    @page_title = "Church Members"
    @tab        = "profile"

    if params[:church]
      @church         = Church.find(params[:church])
      @church_members = @church.users
    elsif current_user.church
      @church         = current_user.church
      @church_members = @church.users
    else
      flash[:notice]  = "You have not yet selected a church or organization to belong to. Please update your profile."
      redirect_to update_profile_path
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
    @user_country   = @user.country ? @user.country.printable_name : ""
    @user_church    = @user.church ?  @user.church.name : ""
    @user_state     = @user.state ?  @user.state.name : ""
    
    # -- Process Form --
    if request.put? # For some reason this is a 'put' not a 'post'
      if @user.update_profile(params[:user])
        flash[:notice] = "Profile successfully updated"
        redirect_to home_path
      else
        render :action => update_profile
      end
    end
    
    
  end # method: update_profile

  # ----------------------------------------------------------------------------------------------------------
  # Autcomplete for Country Names
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
    
    all_states = State.find(:all, :select => 'name')
    
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

end # Class
