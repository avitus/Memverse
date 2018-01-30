class ProfileController < ApplicationController

  add_breadcrumb "Home", :root_path
  add_breadcrumb "Account", :current_user

  before_action :authenticate_user!, :except => :unsubscribe

  # ----------------------------------------------------------------------------------------------------------
  # Show Church Members
  # ----------------------------------------------------------------------------------------------------------
  def show_church

    @tab = "profile"
    @sub = "mychurch"

    add_breadcrumb I18n.t('profile_menu.My Church'), :church_path

    if params[:church]
      @church         = Church.find(params[:church])
      @users          = @church.users.order('memorized DESC')
    elsif current_user.church
      @church         = current_user.church
      @users          = @church.users.order('memorized DESC')
    else
      flash[:notice]  = "You have not yet selected a church or organization to belong to. Please update your profile."
      redirect_to update_profile_path
    end

  end

  # ----------------------------------------------------------------------------------------------------------
  # Unsubscribe user from email
  # ----------------------------------------------------------------------------------------------------------
  def unsubscribe
    email_address = params[:email]

    u = User.find_by_email(email_address)

    if u
      if u.unsubscribe
        flash[:notice] = "You have been unsubscribed from all Memverse emails."
        Rails.logger.info("*** User #{u.login} unsubscribed from all emails")
      else
        flash[:notice] = "Sorry. We failed to save the changes to your email preferences."
        Rails.logger.error("=====> Couldn't execute email unsubscribe request for #{email_address}")
      end
    else
      flash[:notice] = "We couldn't find a user with that email address"
      Rails.logger.warn("=====> Couldn't find user with email address #{email_address}")
    end

  end


  # ----------------------------------------------------------------------------------------------------------
  # Update Profile - this allows users to see the update profile form. Requests handled through "update" action
  # ----------------------------------------------------------------------------------------------------------
  def update_profile

    # -- Tabs and Title --
    @tab = "profile"
    @sub = "prof"

    add_breadcrumb I18n.t('profile_menu.Profile'), :update_profile_path

    # -- Display Form --
    @user           = current_user
    @user_country   = @user.country ?         @user.country.printable_name  : ""
    @user_church    = @user.church ?          @user.church.name             : ""
    @user_group     = @user.group ?           @user.group.name              : ""
    @user_state     = @user.american_state ?  @user.american_state.name     : ""

    @trans = Translation.select_options(except: [:SMPB, :SMPC])

  end # method: update_profile

  # ----------------------------------------------------------------------------------------------------------
  # "Update" method (handles form request from update_profile method)
  # Input: params[:user]
  # Output: JSON object
  # ----------------------------------------------------------------------------------------------------------
  def update
    @user = current_user

    if @user.update_profile( params[:user] ) # successful update

      # Alert user to email change if necessary
      if @user.unconfirmed_email   # user has requested email change but hasn't yet confirmed it
        flash[:notice] = I18n.t("profile.update_profile.Confirm Email Flash")
      else
        flash[:notice] = I18n.t("profile.update_profile.Profile Saved Flash")
      end

      # Complete quest. This should really be refactored at some point.
      q = Quest.find_by_url(url_for(:action => 'update_profile', :controller => 'profile', :only_path => false))
      if q && current_user.quests.where(:id => q.id).empty?
        q.check_quest_off(current_user)
        flash.keep[:notice] = "You have completed the task: #{q.task}"
      end

      redirect_to root_path

    else # errors
      flash[:notice] = "Could not update profile: " + @user.errors.full_messages.to_sentence
      redirect_to :action => "update_profile"
    end
  end

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

    query         = params[:term]
    query_length  = query.length

    all_countries = Country.find(:all, :select => 'printable_name')

    all_countries.each { |country|
      name = country.printable_name
      if name[0...query_length].downcase == query.downcase
        @suggestions << name
      end
    }

    render :json => @suggestions.to_json

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

    query         = params[:term]
    query_length  = query.length

    all_states = AmericanState.find(:all, :select => 'name')

    all_states.each { |state|
      name = state.name
      if name[0...query_length].downcase == query.downcase
        @suggestions << name
      end
    }

    render :json => @suggestions.to_json

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

    query         = params[:term]
    query_length  = query.length

    all_churches = Church.find(:all, :select => 'name')

    all_churches.each { |church|
      name = church.name
      if name[0...query_length].downcase == query.downcase
        @suggestions << name
      end
    }

    render :json => @suggestions.to_json

  end

  # ----------------------------------------------------------------------------------------------------------
  # Autcomplete for Group Names
  # Input: params[:query]
  # Output: JSON object
  # ----------------------------------------------------------------------------------------------------------
  def group_autocomplete
    # Return country list in JSON format
    #    {
    #       query:'Li',
    #       suggestions:['Liberia','Libyan Arab Jamahiriya','Liechtenstein','Lithuania'],
    #       data:['LR','LY','LI','LT']
    #    }

    @suggestions = Array.new

    query         = params[:term]
    query_length  = query.length

    all_groups = Group.find(:all, :select => 'name')

    all_groups.each { |group|
      name = group.name
      if name[0...query_length].downcase == query.downcase
        @suggestions << name
      end
    }

    render :json => @suggestions.to_json

  end

  # ----------------------------------------------------------------------------------------------------------
  # Set translation (used for QuickStart)
  # ----------------------------------------------------------------------------------------------------------
  def set_translation
    tl = params[:tl]
    current_user.translation = tl
    current_user.save
    head :ok
  end

  # ----------------------------------------------------------------------------------------------------------
  # Set time allocation (used for QuickStart)
  # ----------------------------------------------------------------------------------------------------------
  def set_time_alloc
    time_allocation = params[:time]
    current_user.time_allocation = time_allocation
    current_user.save
    head :ok
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
    @tab = "profile"
    @sub = "myrefs"

    @user = User.find(params[:id]) || current_user

    add_breadcrumb I18n.t('profile_menu.Referrals'), :referrals_path

    @referrer  = User.find(@user.referred_by) if @user.referred_by

    # Clean up users who have referred themselves
    # TODO: This section can be removed since we now prevent this from happening
    if @user == @referrer
      flash[:notice] = "You can't refer yourself!"
      @user.referred_by = nil
      @user.save
      @referrer = nil
    end

    @referees  = @user.referrals

    @level_two = @referees.collect { |r| r.referrals }.flatten
  end

  # ----------------------------------------------------------------------------------------------------------
  # Interactive User Search (To Find Referrer)
  # ----------------------------------------------------------------------------------------------------------
  def search_user

    search_param = params[:search_param]
    @user_list   = Array.new

    logger.debug("Searching for ... #{search_param.inspect}")

    # TODO: Is there a better way to do this search?

    if !search_param.empty?

      @user_list =  User.where(name: search_param).limit(5)

      if @user_list.empty?
        @user_list =  User.where(email: search_param).limit(5)
      end

      if @user_list.empty?
        @user_list =  User.where(login: search_param).limit(5)
      end

    end

    render :partial => 'search_user', :layout=>false
  end

  # ----------------------------------------------------------------------------------------------------------
  # Init for set referrer page
  # ----------------------------------------------------------------------------------------------------------
  def set_referrer
    @user_list = Array.new
  end

end # Class
