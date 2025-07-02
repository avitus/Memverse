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
      # Create the Consistency badges that would normally be created in seeds
      @consistency_gold = FactoryBot.create(:badge, name: "Consistency", color: "gold", description: "Complete 350 sessions in a year")
      @consistency_silver = FactoryBot.create(:badge, name: "Consistency", color: "silver", description: "Complete 325 sessions in a year")
      @consistency_bronze = FactoryBot.create(:badge, name: "Consistency", color: "bronze", description: "Complete 300 sessions in a year")
      
      # Create the associated quests for each badge
      @gold_quest = FactoryBot.create(:quest, badge: @consistency_gold, objective: 'Annual Sessions', quantity: 350, task: "Complete 350 sessions in a year")
      @silver_quest = FactoryBot.create(:quest, badge: @consistency_silver, objective: 'Annual Sessions', quantity: 325, task: "Complete 325 sessions in a year")
      @bronze_quest = FactoryBot.create(:quest, badge: @consistency_bronze, objective: 'Annual Sessions', quantity: 300, task: "Complete 300 sessions in a year")
      
      @badge  = @consistency_silver
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
      
      bronze_badge  = @consistency_bronze
      bronze_quests = bronze_badge.quests      
      bronze_quests.each { |q| @user.quests << q }
      
      bronze_badge.achieved?(@user).should be false  
    end
    
    it "should remove lower level badges when a higher level badge is earned" do
      # award silver badge
      @user.badges << @badge 
      
      # award gold badge to user
      gold_badge = @consistency_gold
      gold_badge.award_badge(@user) 
      
      # user should no longer have the silver badge ...
      @badge.achieved?(@user).should be false
      # ... but it should still exist and be able to be awarded to other users
      Badge.exists?(:name => "Consistency", :color => "silver").should be true
    end
    
  end
  
  it "should only allow a user to have one badge in a series" do
    # Create the Consistency badges that would normally be created in seeds
    @gold   = FactoryBot.create(:badge, name: "Consistency", color: "gold", description: "Complete 350 sessions in a year")
    @bronze = FactoryBot.create(:badge, name: "Consistency", color: "bronze", description: "Complete 300 sessions in a year")
    
    # Create the associated quests for each badge
    FactoryBot.create(:quest, badge: @gold, objective: 'Annual Sessions', quantity: 350, task: "Complete 350 sessions in a year")
    FactoryBot.create(:quest, badge: @bronze, objective: 'Annual Sessions', quantity: 300, task: "Complete 300 sessions in a year")
    
    @bronze.award_badge(@user)
    @gold.award_badge(@user)
    
    @user.badges.where(:name => "Consistency").length.should == 1
    @user.badges.where(:name => "Consistency").first.color.should == "gold"
  end
    
end
