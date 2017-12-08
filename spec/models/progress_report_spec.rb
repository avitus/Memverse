require 'spec_helper'

describe ProgressReport do
  
  before(:each) do
    @user = FactoryBot.create(:user)     
  end
  
  it "should count all of the progress reports to date" do
    @pr1 = FactoryBot.build(:progress_report, :entry_date => '2012-12-01', :user => @user)
    @pr1.save

    @pr2 = FactoryBot.build(:progress_report, :entry_date => '2012-12-02', :user => @user)
    @pr2.save

    @pr3 = FactoryBot.build(:progress_report, :entry_date => '2012-12-04', :user => @user)
    @pr3.save
    
    @pr3.reload.consistency.should == 2 # last progress report is not counted
  end
  
  it "should only count activity in past 12 months" do
    @pr1 = FactoryBot.create(:progress_report, :entry_date => '2011-12-01', :user => @user)
    @pr2 = FactoryBot.create(:progress_report, :entry_date => '2012-01-04', :user => @user)
    @pr3 = FactoryBot.create(:progress_report, :entry_date => '2012-03-04', :user => @user)
    @pr4 = FactoryBot.create(:progress_report, :entry_date => '2012-12-01', :user => @user)
    @pr5 = FactoryBot.create(:progress_report, :entry_date => '2012-12-02', :user => @user)
    @pr6 = FactoryBot.create(:progress_report, :entry_date => '2012-12-04', :user => @user)
    
    @pr2.consistency.should == 1
    @pr4.consistency.should == 2
    @pr6.consistency.should == 4
  end  
  
  it "should accurately report consistency" do
    @pr1 = FactoryBot.create(:progress_report, :entry_date => '2013-04-02', :user => @user)
    @pr2 = FactoryBot.create(:progress_report, :entry_date => '2013-04-19', :user => @user)
    @pr3 = FactoryBot.create(:progress_report, :entry_date => '2013-04-20', :user => @user)
    @pr4 = FactoryBot.create(:progress_report, :entry_date => '2013-05-04', :user => @user)
    @pr5 = FactoryBot.create(:progress_report, :entry_date => '2013-05-18', :user => @user)
    @pr6 = FactoryBot.create(:progress_report, :entry_date => '2013-05-24', :user => @user) 

    @pr1.consistency.should == 0
    @pr2.consistency.should == 1
    @pr3.consistency.should == 2
    @pr4.consistency.should == 3
    @pr5.consistency.should == 4
    @pr6.consistency.should == 5
  end
end