class BadgesController < ApplicationController

  before_action :authenticate_user!

  def index
  end

  def show
  end

  # ----------------------------------------------------------------------------------------------------------
  # Show badges earned by user
  # ----------------------------------------------------------------------------------------------------------
  def earned_badges

    user = User.find(params[:id])
    @earned_badges = user.badges unless !user

    respond_to do |format|
      format.html  # earned_badges.html.erb
      format.json  { render :json => @earned_badges }
    end

  end

  # ----------------------------------------------------------------------------------------------------------
  # Check whether user has earned any badges
  # ----------------------------------------------------------------------------------------------------------
  def badge_completion_check

    @recently_awarded_badges = Array.new

    # Get badges user is working towards. Check most valuable (gold) badges first
    badges_to_check = current_user.badges_to_strive_for.sort.reverse

    badges_to_check.each do |badge|

      if badge.achieved?(current_user)
        badge.award_badge(current_user)
        @recently_awarded_badges << badge

        if badge.color == "solo"
          broadcast = "#{current_user.name_or_login} has been awarded the #{badge.name} badge"
        else
          broadcast  = "#{current_user.name_or_login} has been awarded a #{badge.color} #{badge.name} badge"
        end
        Tweet.create(:news => broadcast, :user_id => current_user.id, :importance => 2)

      end
    end

    respond_to do |format|
      format.html
      format.json  { render :json => @recently_awarded_badges }
    end

  end

end
