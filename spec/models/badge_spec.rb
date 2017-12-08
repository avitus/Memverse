require 'spec_helper'

describe Badge do
  
  before(:each) do
    @user   = FactoryBot.create(:user)     
  end
  
  it "should create a new instance given a valid attribute" do
    Badge.create!(:name => 'Sermon on the Mount', :description => 'Memorize Matthew 5-7', :color => 'solo')
  end  

  #----------------------------------------------------------------------------------------------
  # Badge hierarchy
  #----------------------------------------------------------------------------------------------    
  describe "should understand badge hierarchy" do
    
    before(:each) do
      @gold_badge   = FactoryBot.create(:badge, :color => "gold")
      @silver_badge = FactoryBot.create(:badge, :color => "silver")
      @bronze_badge = FactoryBot.create(:badge, :color => "bronze")
    end
    
    it "should value a gold medal more than a silver medal" do
      @gold_badge.should be > @silver_badge
    end
    
    it "should value a silver medal more than a bronze medal" do
      @silver_badge.should be > @bronze_badge
    end    
        
  end

  #----------------------------------------------------------------------------------------------
  # Reporting earned badges
  #----------------------------------------------------------------------------------------------   
  describe "should correctly report which badges a user has earned" do
    
    before(:each) do
      @badge  = Badge.where(:name => "Consistency", :color => "silver").first
      @quests = @badge.quests        
    end
        
    it "show a badge as earned if all quests are complete" do
      @quests.each { |q| @user.quests << q }
      @badge.achieved?(@user).should be true
    end

    it "should not show a badge as earned if a quest is incomplete" do
      @badge.achieved?(@user).should be false
    end
    
    it "should not show a badge as earned if user already has a higher level badge" do
      @user.badges << @badge
      
      bronze_badge  = Badge.where(:name => "Consistency", :color => "bronze").first
      bronze_quests = bronze_badge.quests      
      bronze_quests.each { |q| @user.quests << q }
      
      bronze_badge.achieved?(@user).should be false  
    end
    
    it "should remove lower level badges when a higher level badge is earned" do
      # award silver badge
      @user.badges << @badge 
      
      # award gold badge to user
      gold_badge = Badge.where(:name => "Consistency", :color => "gold").first
      gold_badge.award_badge(@user) 
      
      # user should no longer have the silver badge ...
      @badge.achieved?(@user).should be false
      # ... but it should still exist and be able to be awarded to other users
      Badge.exists?(:name => "Consistency", :color => "silver").should be true
    end
    
  end
  
  it "should only allow a user to have one badge in a series" do
    @gold   = Badge.where(:name => "Consistency", :color => "gold").first
    @bronze = Badge.where(:name => "Consistency", :color => "bronze").first
    
    @bronze.award_badge(@user)
    @gold.award_badge(@user)
    
    @user.badges.where(:name => "Consistency").length.should == 1
    @user.badges.where(:name => "Consistency").first.color.should == "gold"
  end
    
end
