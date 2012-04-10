class BadgesController < ApplicationController
  def index
  end

  def show
  end
  
  # ----------------------------------------------------------------------------------------------------------   
  # Show badges earned by user
  # ----------------------------------------------------------------------------------------------------------   
  def earned_badges
    
    @earned_badges = Array.new
    @earned_badges << Badge.where(:name => 'Consistency', :color => 'silver').first # current_user.badges
    @earned_badges << Badge.where(:name => 'Referrer', :color => 'bronze').first
    @earned_badges << Badge.where(:name => 'Sermon on the Mount').first
    
    respond_to do |format|
      format.html  # earned_badges.html.erb
      format.json  { render :json => @earned_badges }
    end    
    
  end

  # ----------------------------------------------------------------------------------------------------------   
  # Check whether user has earned any badges
  # ----------------------------------------------------------------------------------------------------------  
  def badge_completion_check
    # need to handle gold, silver, bronze issue
    # first generate a list of badges the user would be interested in earning i.e. all badges of higher level
    # or unearned solo badges.
    badges_to_check = Badge.all - current_user.badges
    
    
  end    
    
    
end
