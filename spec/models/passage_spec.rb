# encoding: utf-8
require 'spec_helper'

describe Passage do

  before(:each) do
    @user  = User.create!(:name => "Test User", :email => "test@memverse.com", :password => "secret", :password_confirmation => "secret")
  end

  it "should create a new instance given valid attributes" do
    @verse = Verse.create!(:book_index => 1, :book => "Genesis", :chapter => 12, :versenum => 1, :text => "This is a test", :translation => "NIV")
    @mv    = Memverse.create!(:user => @user, :verse => @verse)
    @psg   = Passage.create!(:user_id => @user, :length => 1, :reference => @mv.verse.ref,
                             :book => @mv.verse.book, :chapter => @mv.verse.chapter,
                             :first_verse => @mv.verse.versenum, :last_verse => @mv.verse.versenum,
                             :efactor => @mv.efactor, :test_interval => @mv.test_interval, :rep_n => 1)
  end

  # ALV: This would be nice to do but not sure exactly what I'm trying to achieve here
  # it "should create a new instance from a memverse" do
  #   @verse = Verse.create!(:book_index => 1, :book => "Genesis", :chapter => 12, :versenum => 1, :text => "This is a test", :translation => "NIV")
  #   @mv    = Memverse.create!(:user => @user, :verse => @verse)
  #   @psg   = Passage.create!( @mv.attributes, @mv.verse.attributes )
  # end

  describe "combining two passages" do

    before(:each) do
      # Automatically generates user, memverses and verses through Factory
      @psg1 = FactoryGirl.create(:passage, :book => 'Luke', :chapter => 2, :first_verse => 2, :last_verse => 4)
      @psg2 = FactoryGirl.create(:passage, :book => 'Luke', :chapter => 2, :first_verse => 5, :last_verse => 8)
    end

    it "should merge two adjacent passages" do

      expect {
        @psg1.combine_with( @psg2 )
      }.to change(Passage, :count).by(-1)

      @psg1.first_verse.should == 2
      @psg1.last_verse.should  == 8
      @psg2.memverses.first.passage_id.should == @psg1.id # now associated with first passage

    end

  end

end
