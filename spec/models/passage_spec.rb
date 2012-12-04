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

  # ==============================================================================================
  # Merge two passages into one (note: can be triggered by insertion of missing verse)
  # ==============================================================================================
  describe "combining two passages" do

    before(:each) do
      # Automatically generates user, memverses and verses through Factory
      @psg1 = FactoryGirl.create(:passage, :book => 'Luke', :chapter => 2, :first_verse => 2, :last_verse => 4)
      @psg2 = FactoryGirl.create(:passage, :book => 'Luke', :chapter => 2, :first_verse => 6, :last_verse => 8)
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

  # ==============================================================================================
  # Add a memory verse to an existing passage
  # ==============================================================================================
  describe "add a new verse to a passage" do

    before(:each) do
      @psg = FactoryGirl.create(:passage, :book => 'Leviticus', :chapter => 1, :first_verse => 3, :last_verse => 6)
    end

    it "should correctly add a preceding verse" do
      vs = FactoryGirl.create(:verse, book: 'Leviticus', chapter: 1, versenum: 2)
      mv = FactoryGirl.create(:memverse, verse: vs)

      @psg.expand( mv )

      @psg.first_verse.should == 2
      @psg.last_verse.should == 6
      mv.passage_id.should == @psg.id
    end

    it "should correctly add a subsequent verse" do
      vs = FactoryGirl.create(:verse, book: 'Leviticus', chapter: 1, versenum: 7)
      mv = FactoryGirl.create(:memverse, verse: vs)

      @psg.expand( mv )

      @psg.first_verse.should == 3
      @psg.last_verse.should == 7
      mv.passage_id.should == @psg.id
    end

  end

end
