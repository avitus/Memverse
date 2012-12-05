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
  # Capture Supermemo data from underlying memory verses
  # ==============================================================================================
  it "should summarize Supermemo data from underlying memory verses" do

    # eFactor of these two verses is 2.0 as per factory
    # rep_n and interval are 4 and 5 respectively as per factory
    psg = FactoryGirl.create(:passage, book: 'Nahum', chapter: 1, first_verse: 4, last_verse: 5, length: 2)

    # add an extra memory verse with a different eFactor
    # rep_n = 2, eFactor = 1.4, interval = 1
    vs = FactoryGirl.create(:verse, book: 'Nahum', chapter: 1, versenum: 6)
    mv = FactoryGirl.create(:memverse_without_supermemo_init, :verse => vs, :efactor => 1.4, :rep_n => 2, :test_interval => 3)

    psg.expand( mv )

    psg.test_interval.should == 3
    psg.rep_n.should         == 2
    psg.efactor.should       == 1.8

  end

  # ==============================================================================================
  # Merge two passages into one (note: can be triggered by insertion of missing verse)
  # ==============================================================================================
  describe "combining two passages" do

    it "should merge two adjacent passages" do

      # Automatically generates user, memverses and verses through Factory
      psg1 = FactoryGirl.create(:passage, :book => 'Luke', :chapter => 2, :first_verse => 2, :last_verse => 4)
      psg2 = FactoryGirl.create(:passage, :book => 'Luke', :chapter => 2, :first_verse => 5, :last_verse => 8)

      expect {
        psg1.absorb( psg2 )
      }.to change(Passage, :count).by(-1)

      psg1.first_verse.should == 2
      psg1.last_verse.should  == 8
      psg2.memverses.first.passage_id.should == psg1.id # now associated with first passage

    end

    it "should merge two passages if linking verse is inserted" do

      # Automatically generates user, memverses and verses through Factory
      psg1 = FactoryGirl.create(:passage, :book => 'Mark', :chapter => 2, :first_verse => 2, :last_verse => 4)
      psg2 = FactoryGirl.create(:passage, :book => 'Mark', :chapter => 2, :first_verse => 6, :last_verse => 8)

      vs = FactoryGirl.create(:verse, book: 'Mark', chapter: 2, versenum: 5)
      mv = FactoryGirl.create(:memverse, verse: vs)

      expect {
        psg1.absorb( psg2, mv )
      }.to change(Passage, :count).by(-1)

      psg1.first_verse.should == 2
      psg1.last_verse.should  == 8
      psg2.memverses.first.passage_id.should == psg1.id # now associated with first passage
      mv.passage_id == psg1.id

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

  # ==============================================================================================
  # Complete chapters
  # ==============================================================================================
  describe "check for complete chapters" do

    it "should set flag when entire chapter has been added" do

      psg = FactoryGirl.create(:passage, book: 'Esther', chapter: 10, first_verse: 1, last_verse: 2)
      vs = FactoryGirl.create(:verse, book: 'Esther', chapter: 10, versenum: 3)
      mv = FactoryGirl.create(:memverse, :verse => vs)

      psg.complete_chapter.should be false
      psg.expand( mv )
      psg.complete_chapter.should be true

    end

    it "should accept Psalms with a zero verse" do

      psg = FactoryGirl.create(:passage, book: 'Psalms', chapter: 53, first_verse: 0, last_verse: 5)
      vs = FactoryGirl.create(:verse, book: 'Psalms', chapter: 53, versenum: 6)
      mv = FactoryGirl.create(:memverse, :verse => vs)

      psg.complete_chapter.should be false
      psg.expand( mv )
      psg.complete_chapter.should be true

    end

    describe "should handle corner case of 3 John 1" do

      it "which has 14 verses in NIV" do
        psg = FactoryGirl.create(:passage, book: '3 John', chapter: 1, first_verse: 1, last_verse: 13, translation: 'NIV')
        vs = FactoryGirl.create(:verse, book: '3 John', chapter: 1, versenum: 14)
        mv = FactoryGirl.create(:memverse, :verse => vs)

        psg.complete_chapter.should be false
        psg.expand( mv )
        psg.complete_chapter.should be true
      end

      it "and 15 verses in ESV" do
        psg = FactoryGirl.create(:passage, book: '3 John', chapter: 1, first_verse: 1, last_verse: 14, translation: 'ESV')
        vs = FactoryGirl.create(:verse, book: '3 John', chapter: 1, versenum: 15)
        mv = FactoryGirl.create(:memverse, :verse => vs)

        psg.complete_chapter.should be false
        psg.expand( mv )
        psg.complete_chapter.should be true
      end

    end




  end

end
