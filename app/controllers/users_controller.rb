class UsersController < ApplicationController
  skip_before_filter :verify_authenticity_token, :only => :create
  before_filter :authenticate_user!, :only => :show

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

  protected

end
