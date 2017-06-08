require 'spec_helper'

describe ProgressReport do
  
  before(:each) do
    @user = FactoryGirl.create(:user)     
  end
  
  it "should count all of the progress reports to date" do
    @pr1 = FactoryGirl.create(:progress_report, :entry_date => '2012-12-01', :user => @user)
    @pr2 = FactoryGirl.create(:progress_report, :entry_date => '2012-12-02', :user => @user)
    @pr3 = FactoryGirl.create(:progress_report, :entry_date => '2012-12-04', :user => @user)
    
    @pr1.reload
    @pr2.reload
    @pr3.reload

    puts @pr3
    puts @pr2
    puts @pr1

    @pr3.reload.consistency.should == 3
    @pr2.reload.consistency.should == 2
    @pr1.reload.consistency.should == 1
  end
  
  it "should only count activity in past 12 months" do
    @pr1 = FactoryGirl.create(:progress_report, :entry_date => '2011-12-01', :user => @user)
    @pr2 = FactoryGirl.create(:progress_report, :entry_date => '2012-01-04', :user => @user)
    @pr3 = FactoryGirl.create(:progress_report, :entry_date => '2012-03-04', :user => @user)
    @pr4 = FactoryGirl.create(:progress_report, :entry_date => '2012-12-01', :user => @user)
    @pr5 = FactoryGirl.create(:progress_report, :entry_date => '2012-12-02', :user => @user)
    @pr6 = FactoryGirl.create(:progress_report, :entry_date => '2012-12-04', :user => @user)
    


    @pr2.consistency.should == 2
    @pr4.consistency.should == 3
    @pr6.consistency.should == 5
  end  
  
  it "should accurately report consistency" do
    @pr1 = FactoryGirl.create(:progress_report, :entry_date => '2013-04-02', :user => @user)
    @pr2 = FactoryGirl.create(:progress_report, :entry_date => '2013-04-19', :user => @user)
    @pr3 = FactoryGirl.create(:progress_report, :entry_date => '2013-04-20', :user => @user)
    @pr4 = FactoryGirl.create(:progress_report, :entry_date => '2013-05-04', :user => @user)
    @pr5 = FactoryGirl.create(:progress_report, :entry_date => '2013-05-18', :user => @user)
    @pr6 = FactoryGirl.create(:progress_report, :entry_date => '2013-05-24', :user => @user) 

    @pr1.consistency.should == 1
    @pr2.consistency.should == 2
    @pr3.consistency.should == 3
    @pr4.consistency.should == 4
    @pr5.consistency.should == 5
    @pr6.consistency.should == 6
  end
end