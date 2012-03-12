require 'spec_helper'
require 'pp'

describe Memverse do
  
  before(:each) do    
    @user  = FactoryGirl.create(:user)
    @verse = FactoryGirl.create(:verse) 
  end
  
  it "should create a new instance given a valid attribute" do
    Memverse.create!(:user => @user, :verse => @verse)
  end

#  --------------------------------------------------------------------------------------------------------------
#  The after_create hooks don't seem to be called so testing this functionality in the controller for now. 
#  Would prefer to have it at the model level, though  
#  ---------------------------------------------------------------------------------------------------------------

#  describe "Verse Linking" do
#    
#    before(:each) do
#      
#      @passage = Array.new
#         
#      for i in 1..6
#        verse       = Factory(:verse, :book_index => 19, :book => "Psalms", :chapter => '1', :versenum => i)
#        @passage[i] = Factory(:memverse, :user => @user, :verse => verse)
#      end      
#      
#    end
#    
#    it "should link a new verse to the following verse" do
#      
#      pp @passage[1]
#      pp @passage[2]
#      pp @passage[3]
#      pp @passage[4]
#      pp @passage[5]
#      pp @passage[6]
#      
#      @passage[2].next_verse.should  == @passage[3].id
#    end
#
#    it "should link a new verse to the previous verse" do
#      @passage[2].prev_verse.should  == @passage[1].id
#    end
#    
#    it "should link the following verse to the new verse" do
#      @passage[3].prev_verse.should  == @passage[2].id      
#    end
#
#    it "should link the previous verse to the new verse" do
#      @passage[1].next_verse.should  == @passage[2].id
#    end
#
#    it "should point the new verse to the first verse" do
#      @passage[2].first_verse.should == @passage[1].id
#    end
#    
#    it "should not point the first verse to anything" do
#      @passage[1].first_verse.should be_nil
#    end    
#    
#  end
  
end