class BadgesController < ApplicationController
  def index
  end

  def show
  end
  
  # ----------------------------------------------------------------------------------------------------------   
  # Show badges earned by user
  # ----------------------------------------------------------------------------------------------------------   
  def earned_badges
    
    @earned_badges = Badge.all # current_user.badges
    
    respond_to do |format|
      format.html  # earned_badges.html.erb
      format.json  { render :json => @earned_badges }
    end    
    
  end
    
end
