# encoding: utf-8
require 'spec_helper'

describe Passage do

  before(:each) do
    @user  = User.create!(:name => "Test User", :email => "test@memverse.com", :password => "secret", :password_confirmation => "secret")
  end

  it "should create a new instance given valid attributes" do
    @verse = Verse.create!(:book_index => 1, :book => "Genesis", :chapter => 12, :versenum => 1, :text => "This is a test", :translation => "NIV")
    @mv    = Memverse.create!(:user => @user, :verse => @verse)
    @psg   = Passage.create!(:user_id => @user.id, :length => 1, :reference => @mv.verse.ref,
                             :book => @mv.verse.book, :chapter => @mv.verse.chapter, :translation => @mv.verse.translation,
                             :first_verse => @mv.verse.versenum, :last_verse => @mv.verse.versenum,
                             :efactor => @mv.efactor, :test_interval => @mv.test_interval, :rep_n => 1)
  end

  # ==============================================================================================
  # Automatically create new passage when a memory verse is created
  # ==============================================================================================
  describe "add new memory verse to a passage" do

  end

  # ==============================================================================================
  # Remove a passage and associated memverses
  # ==============================================================================================
  describe "remove (destroy) a passage" do

    it "should remove the passage" do
      psg = FactoryGirl.create(:passage, book: 'Psalms', chapter: 30, first_verse: 6, last_verse: 12, length: 7)
      expect {
        psg.remove
      }.to change(Passage, :count).by(-1)  
    end

    it "should remove the associated memverses" do
      psg = FactoryGirl.create(:passage, book: 'Psalms', chapter: 30, first_verse: 6, last_verse: 12, length: 7)
      expect {
        psg.remove
      }.to change(Memverse, :count).by(-7)  
    end

  end

  # ==============================================================================================
  # Automatically create subsections in a passage
  # ==============================================================================================
  describe "automatically handle subsections" do

    before(:each) do
      FactoryGirl.create(:uberverse, :book => 'Psalms', :chapter => 22, :book_index => 19, :versenum =>  1, :subsection_end =>   0)
      FactoryGirl.create(:uberverse, :book => 'Psalms', :chapter => 22, :book_index => 19, :versenum =>  2, :subsection_end =>   0)
      FactoryGirl.create(:uberverse, :book => 'Psalms', :chapter => 22, :book_index => 19, :versenum =>  3, :subsection_end =>  50)
      FactoryGirl.create(:uberverse, :book => 'Psalms', :chapter => 22, :book_index => 19, :versenum =>  4, :subsection_end =>   0)
      FactoryGirl.create(:uberverse, :book => 'Psalms', :chapter => 22, :book_index => 19, :versenum =>  5, :subsection_end =>   0)
      FactoryGirl.create(:uberverse, :book => 'Psalms', :chapter => 22, :book_index => 19, :versenum =>  6, :subsection_end =>   0)
      FactoryGirl.create(:uberverse, :book => 'Psalms', :chapter => 22, :book_index => 19, :versenum =>  7, :subsection_end =>   0)
      FactoryGirl.create(:uberverse, :book => 'Psalms', :chapter => 22, :book_index => 19, :versenum =>  8, :subsection_end =>   2)
      FactoryGirl.create(:uberverse, :book => 'Psalms', :chapter => 22, :book_index => 19, :versenum =>  9, :subsection_end =>   0)
      FactoryGirl.create(:uberverse, :book => 'Psalms', :chapter => 22, :book_index => 19, :versenum => 10, :subsection_end =>  20)
      FactoryGirl.create(:uberverse, :book => 'Psalms', :chapter => 22, :book_index => 19, :versenum => 11, :subsection_end =>   0)
      FactoryGirl.create(:uberverse, :book => 'Psalms', :chapter => 22, :book_index => 19, :versenum => 12, :subsection_end =>   3)
      FactoryGirl.create(:uberverse, :book => 'Psalms', :chapter => 22, :book_index => 19, :versenum => 13, :subsection_end =>   0)
      FactoryGirl.create(:uberverse, :book => 'Psalms', :chapter => 22, :book_index => 19, :versenum => 14, :subsection_end =>   0)
      FactoryGirl.create(:uberverse, :book => 'Psalms', :chapter => 22, :book_index => 19, :versenum => 15, :subsection_end =>   0)
      FactoryGirl.create(:uberverse, :book => 'Psalms', :chapter => 22, :book_index => 19, :versenum => 16, :subsection_end =>   0)
      FactoryGirl.create(:uberverse, :book => 'Psalms', :chapter => 22, :book_index => 19, :versenum => 17, :subsection_end =>   0)
      FactoryGirl.create(:uberverse, :book => 'Psalms', :chapter => 22, :book_index => 19, :versenum => 18, :subsection_end =>   0)
      FactoryGirl.create(:uberverse, :book => 'Psalms', :chapter => 22, :book_index => 19, :versenum => 19, :subsection_end =>   0)
      FactoryGirl.create(:uberverse, :book => 'Psalms', :chapter => 22, :book_index => 19, :versenum => 20, :subsection_end =>   0)
      FactoryGirl.create(:uberverse, :book => 'Psalms', :chapter => 22, :book_index => 19, :versenum => 21, :subsection_end =>   0)
      FactoryGirl.create(:uberverse, :book => 'Psalms', :chapter => 22, :book_index => 19, :versenum => 22, :subsection_end =>   0)
    end

    it "should divide passages into subsections automagically" do
      psg = FactoryGirl.create(:passage, book: 'Psalms', chapter: 22, first_verse: 1, last_verse: 6, length: 6)
      psg.auto_subsection
      psg.memverses.first.subsection.should == 0
      psg.memverses.last.subsection.should  == 1
    end

    it "should find the most likely breakpoint in the passage" do
      psg = FactoryGirl.create(:passage, book: 'Psalms', chapter: 22, first_verse: 7, last_verse: 13, length: 7)
      psg.auto_subsection # Should create only two subsections with verse 10 at end of 1st subsection
      psg.memverses.first.subsection.should == 0
      psg.memverses.last.subsection.should  == 1
      psg.memverses.where(:subsection => 1).first.verse.versenum.should == 11
    end

    it "should limit the number of subsections in a passage" do
      psg = FactoryGirl.create(:passage, book: 'Psalms', chapter: 22, first_verse: 1, last_verse: 13, length: 13)
      psg.auto_subsection(5)
      psg.memverses.first.subsection.should == 0
      psg.memverses.last.subsection.should  == 2
      psg.memverses.where(:subsection => 1).first.verse.versenum.should ==  4
      psg.memverses.where(:subsection => 2).first.verse.versenum.should == 11
    end

    it "should not subsection passages which have no information about ending verses" do
      psg = FactoryGirl.create(:passage, book: 'Psalms', chapter: 22, first_verse: 13, last_verse: 22, length: 10)
      psg.auto_subsection
      psg.memverses.first.subsection.should == 0
      psg.memverses.last.subsection.should  == 0
    end

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
      psg1 = FactoryGirl.create(:passage, user: @user, book: 'Luke', chapter: 2, first_verse: 2, last_verse: 4)
      psg2 = FactoryGirl.create(:passage, user: @user, book: 'Luke', chapter: 2, first_verse: 5, last_verse: 8)

      expect {
        psg1.absorb( psg2 )
      }.to change(Passage, :count).by(-1)

      psg1.first_verse.should == 2
      psg1.last_verse.should  == 8
      psg1.book_index.should == 42
      psg2.memverses.first.passage_id.should == psg1.id # now associated with first passage

    end

    it "should merge two passages if linking verse is inserted" do

      # Automatically generates user, memverses and verses through Factory

      # Mark 2:2-4
      psg1 = FactoryGirl.create(:passage, user: @user, book: 'Mark', chapter: 2, first_verse: 2, last_verse: 4, length: 3)
      # Mark 2:6-8
      psg2 = FactoryGirl.create(:passage, user: @user, book: 'Mark', chapter: 2, first_verse: 6, last_verse: 8, length: 3)

      mv2 = psg2.memverses.first # need to ensure that this verse is associated with psg1 after combination

      # Mark 2:5
      vs = FactoryGirl.create(:verse, book: 'Mark', chapter: 2, versenum: 5)
      mv = FactoryGirl.create(:memverse, user: @user, verse: vs)  # triggers after_create call_back to add memory verse to passage

      psg1.reload
      mv2.reload

      # Assertions
      psg1.first_verse.should == 2
      psg1.last_verse.should  == 8
      psg1.length.should      == 7
      psg1.book_index.should  == 41
      mv.passage_id           == psg1.id # link mv associated with first passage
      mv2.passage_id.should   == psg1.id # now associated with first passage

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
      @psg.book_index.should == 3
      mv.passage_id.should == @psg.id
    end

    it "should correctly add a subsequent verse" do
      vs = FactoryGirl.create(:verse, book: 'Leviticus', chapter: 1, versenum: 7)
      mv = FactoryGirl.create(:memverse, verse: vs)

      @psg.expand( mv )

      @psg.first_verse.should == 3
      @psg.last_verse.should == 7
      @psg.book_index.should == 3
      mv.passage_id.should == @psg.id
    end

  end

  # ==============================================================================================
  # Deleting memory verses from passage
  # ==============================================================================================
  describe "delete a memory verse from an existing passage" do

    before(:each) do
      @psg = FactoryGirl.create(:passage, :book => 'Proverbs', :chapter => 3, :first_verse => 2, :last_verse => 10)
    end

    it "should correctly delete the first verse of the passage" do
      mv = @psg.memverses.includes(:verse).order('verses.versenum').first
      mv.destroy

      @psg.reload.length.should == 8
      @psg.first_verse.should == 3
      @psg.last_verse.should == 10
    end

    it "should correctly delete the last verse of the passage" do
      mv = @psg.memverses.includes(:verse).order('verses.versenum').last
      mv.destroy

      @psg.reload.length.should == 8
      @psg.first_verse.should == 2
      @psg.last_verse.should == 9
    end

    it "should correctly delete a verse in the middle of the passage" do
      mv = @psg.memverses.includes(:verse).where('verses.versenum' => 5).first
      last_mv = @psg.memverses.includes(:verse).order('verses.versenum').last

      expect {
        mv.destroy
      }.to change(Passage, :count).by(1)

      last_mv.reload
      psg2 = last_mv.passage

      @psg.reload.length.should == 3
      @psg.first_verse.should == 2
      @psg.last_verse.should == 4
      @psg.reference.should == "Proverbs 3:2-4"

      psg2.first_verse.should == 6
      psg2.last_verse.should == 10
      psg2.length.should == 5
      psg2.memverses.count.should == 5
      psg2.reference.should == "Proverbs 3:6-10"
    end


    it "should correctly delete two adjacent verses in the middle of the passage" do
      mv1     = @psg.memverses.includes(:verse).where('verses.versenum' => 5).first
      mv2     = @psg.memverses.includes(:verse).where('verses.versenum' => 6).first
      last_mv = @psg.memverses.includes(:verse).order('verses.versenum').last

      expect {
        mv1.destroy
        @psg.reload
        mv2.reload  # Need to reload mv2 since it now belongs to a different passage
        mv2.destroy
      }.to change(Passage, :count).by(1)

      last_mv.reload
      psg2 = last_mv.passage

      @psg.reload
      @psg.length.should == 3
      @psg.first_verse.should == 2
      @psg.last_verse.should == 4
      @psg.reference.should == "Proverbs 3:2-4"

      psg2.first_verse.should == 7
      psg2.last_verse.should == 10
      psg2.length.should == 4
      psg2.memverses.count.should == 4
      psg2.reference.should == "Proverbs 3:7-10"
    end

    it "should remove passage from database if it has no verses" do
      expect {
        @psg.memverses.destroy_all
      }.to change(Passage, :count).by(-1)

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
      vs  = FactoryGirl.create(:verse, book: 'Psalms', chapter: 53, versenum: 6)
      mv  = FactoryGirl.create(:memverse, :verse => vs)

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
        vs  = FactoryGirl.create(:verse, book: '3 John', chapter: 1, versenum: 15)
        mv  = FactoryGirl.create(:memverse, :verse => vs)

        psg.complete_chapter.should be false
        psg.expand( mv )
        psg.complete_chapter.should be true
      end

    end


  end

end
