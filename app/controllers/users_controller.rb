class UsersController < ApplicationController

  skip_before_action :verify_authenticity_token, :only => :create

  before_action :authenticate_user!

  add_breadcrumb "Home", :root_path

  # ----------------------------------------------------------------------------------------------------------
  # Show user account page
  # ----------------------------------------------------------------------------------------------------------
  def show
    @tab = "profile"
    @sub = "dash"
    @user = User.find(params[:id]) || current_user

    if @user == current_user
      add_breadcrumb I18n.t('menu.profile'), :current_user
      # Check for completed tasks
      if quests = @user.check_for_completed_quests
        flash.now[:notice] = "Great. You have completed the following task: #{quests.length}"
      end

      # Has user leveled up?
      if @user.check_for_level_up
        flash.now[:notice] = "Congratulations!! You have reached level #{@user.level}."

        case @user.level
        when 1..4 then importance = 5
        when 5..20 then importance = 3
        else importance = 1
        end

        Tweet.create(:news => "#{@user.name_or_login} reached level #{@user.level}", :user_id => @user.id, :importance => importance)
      end

      @current_user_quests      = @user.current_uncompleted_quests
      @current_completed_quests = @user.current_completed_quests

    else # This is not current user
      add_breadcrumb I18n.t( :user_profile, :scope => 'page_titles', :name => @user.name_or_login), @user_path
    end

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @user }
    end

  end

  # ----------------------------------------------------------------------------------------------------------
  # Current user progression
  # ----------------------------------------------------------------------------------------------------------
  def current_user_progression
    user_progression = current_user && current_user.progression[:level].split('-')[0].to_i
    render :json => { :progression => user_progression }
  end

  # ----------------------------------------------------------------------------------------------------------
  # Reset memorization schedule
  # ----------------------------------------------------------------------------------------------------------
  def reset_schedule
  	due_today = current_user ? current_user.reset_memorization_schedule : 0
  	render :json => {:due_verses => due_today }
  end

  # ----------------------------------------------------------------------------------------------------------
  # Update user's reference recall score
  # ----------------------------------------------------------------------------------------------------------
  def update_ref_grade

    current_user.update_attribute(:ref_grade, params[:score] )

    respond_to do |format|
      format.json { render :json => current_user.ref_grade }
    end

  end

  # ----------------------------------------------------------------------------------------------------------
  # Update user's accuracy score
  # ----------------------------------------------------------------------------------------------------------
  def update_accuracy

    current_user.update_attribute(:accuracy, params[:score] )

    respond_to do |format|
      format.json { render :json => current_user.accuracy }
    end

  end


  def user_params
    params.require(:user)
      .permit(:login, :email, :name, :password, :password_confirmation, :current_password,
              :identity_url, :remember_me, :newsletters, :reminder_freq, :last_reminder,
              :church, :group, :country, :american_state, :show_echo, :max_interval,
              :mnemonic_use, :all_refs, :referred_by, :auto_work_load, :show_email,
              :provider, :uid, :translation, :time_allocation, :quiz_alert,
              :device_token, :device_type)
  end

  protected

end
