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
    
end
