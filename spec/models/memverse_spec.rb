require 'spec_helper'

describe Memverse do
  
  before(:each) do    
    @user  = FactoryGirl.create(:user)
    @verse = FactoryGirl.create(:verse) 
  end
  
  it "should create a new instance given a valid attribute" do
    Memverse.create!(:user => @user, :verse => @verse)
  end
  
  
  
end