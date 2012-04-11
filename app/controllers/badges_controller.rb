class BadgesController < ApplicationController
  
  before_filter :authenticate_user!
  
  def index
  end

  def show
  end
  
  # ----------------------------------------------------------------------------------------------------------   
  # Show badges earned by user
  # ----------------------------------------------------------------------------------------------------------   
  def earned_badges
    
    @earned_badges = current_user.badges

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
    
    # Get badges user is working towards
    badges_to_check = current_user.badges_to_strive_for
    
    badges_to_check.each do |badge|
      if badge.achieved?(current_user)
        badge.award_badge(current_user)
        @recently_awarded_badges << badge
      end
    end  
      
    respond_to do |format|
      format.html  
      format.json  { render :json => @recently_awarded_badges }
    end        
      
  end    
    
end
