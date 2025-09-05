# encoding: utf-8
require 'spec_helper'

describe Passage do

  before(:each) do
    @user  = User.create!(:name => "Test User", :email => "test@memverse.com", :password => "secret", :password_confirmation => "secret")
    @user.confirm if @user.respond_to?(:confirm)  # Skip email confirmation in tests
  end

  it "should create a new instance given valid attributes" do
    @verse = Verse.create!(:book_index => 19, :book => "Psalms", :chapter => 117, :versenum => 1, :text => "Praise the LORD, all you nations; extol him, all you peoples.", :translation => "NIV")
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
      psg = FactoryBot.create(:passage, book: 'Psalms', chapter: 117, first_verse: 1, last_verse: 2, length: 2)
      expect {
        psg.remove
      }.to change(Passage, :count).by(-1)  
    end

    it "should remove the associated memverses" do
      psg = FactoryBot.create(:passage, book: 'Psalms', chapter: 117, first_verse: 1, last_verse: 2, length: 2)
      expect {
        psg.remove
      }.to change(Memverse, :count).by(-2)  
    end

  end

  # ==============================================================================================
  # Automatically create subsections in a passage
  # ==============================================================================================
  describe "automatically handle subsections" do

    before(:each) do
      FactoryBot.create(:uberverse, :book => 'Psalms', :chapter => 22, :book_index => 19, :versenum =>  1, :subsection_end =>   0)
      FactoryBot.create(:uberverse, :book => 'Psalms', :chapter => 22, :book_index => 19, :versenum =>  2, :subsection_end =>   0)
      FactoryBot.create(:uberverse, :book => 'Psalms', :chapter => 22, :book_index => 19, :versenum =>  3, :subsection_end =>  50)
      FactoryBot.create(:uberverse, :book => 'Psalms', :chapter => 22, :book_index => 19, :versenum =>  4, :subsection_end =>   0)
      FactoryBot.create(:uberverse, :book => 'Psalms', :chapter => 22, :book_index => 19, :versenum =>  5, :subsection_end =>   0)
      FactoryBot.create(:uberverse, :book => 'Psalms', :chapter => 22, :book_index => 19, :versenum =>  6, :subsection_end =>   0)
      FactoryBot.create(:uberverse, :book => 'Psalms', :chapter => 22, :book_index => 19, :versenum =>  7, :subsection_end =>   0)
      FactoryBot.create(:uberverse, :book => 'Psalms', :chapter => 22, :book_index => 19, :versenum =>  8, :subsection_end =>   2)
      FactoryBot.create(:uberverse, :book => 'Psalms', :chapter => 22, :book_index => 19, :versenum =>  9, :subsection_end =>   0)
      FactoryBot.create(:uberverse, :book => 'Psalms', :chapter => 22, :book_index => 19, :versenum => 10, :subsection_end =>  20)
      FactoryBot.create(:uberverse, :book => 'Psalms', :chapter => 22, :book_index => 19, :versenum => 11, :subsection_end =>   0)
      FactoryBot.create(:uberverse, :book => 'Psalms', :chapter => 22, :book_index => 19, :versenum => 12, :subsection_end =>   3)
      FactoryBot.create(:uberverse, :book => 'Psalms', :chapter => 22, :book_index => 19, :versenum => 13, :subsection_end =>   0)
      FactoryBot.create(:uberverse, :book => 'Psalms', :chapter => 22, :book_index => 19, :versenum => 14, :subsection_end =>   0)
      FactoryBot.create(:uberverse, :book => 'Psalms', :chapter => 22, :book_index => 19, :versenum => 15, :subsection_end =>   0)
      FactoryBot.create(:uberverse, :book => 'Psalms', :chapter => 22, :book_index => 19, :versenum => 16, :subsection_end =>   0)
      FactoryBot.create(:uberverse, :book => 'Psalms', :chapter => 22, :book_index => 19, :versenum => 17, :subsection_end =>   0)
      FactoryBot.create(:uberverse, :book => 'Psalms', :chapter => 22, :book_index => 19, :versenum => 18, :subsection_end =>   0)
      FactoryBot.create(:uberverse, :book => 'Psalms', :chapter => 22, :book_index => 19, :versenum => 19, :subsection_end =>   0)
      FactoryBot.create(:uberverse, :book => 'Psalms', :chapter => 22, :book_index => 19, :versenum => 20, :subsection_end =>   0)
      FactoryBot.create(:uberverse, :book => 'Psalms', :chapter => 22, :book_index => 19, :versenum => 21, :subsection_end =>   0)
      FactoryBot.create(:uberverse, :book => 'Psalms', :chapter => 22, :book_index => 19, :versenum => 22, :subsection_end =>   0)
    end

    it "should divide passages into subsections automagically" do
      psg = FactoryBot.create(:passage, book: 'Psalms', chapter: 22, first_verse: 1, last_verse: 6, length: 6)
      psg.auto_subsection
      expect(psg.memverses.first.subsection).to eq(0)
      expect(psg.memverses.last.subsection).to eq(1)
    end

    it "should find the most likely breakpoint in the passage" do
      psg = FactoryBot.create(:passage, book: 'Psalms', chapter: 22, first_verse: 7, last_verse: 13, length: 7)
      psg.auto_subsection # Should create only two subsections with verse 10 at end of 1st subsection
      expect(psg.memverses.first.subsection).to eq(0)
      expect(psg.memverses.last.subsection).to eq(1)
      expect(psg.memverses.where(:subsection => 1).first.verse.versenum).to eq(11)
    end

    it "should limit the number of subsections in a passage" do
      psg = FactoryBot.create(:passage, book: 'Psalms', chapter: 22, first_verse: 1, last_verse: 13, length: 13)
      psg.auto_subsection(5)
      expect(psg.memverses.first.subsection).to eq(0)
      expect(psg.memverses.last.subsection).to eq(2)
      expect(psg.memverses.where(:subsection => 1).first.verse.versenum).to eq(4)
      expect(psg.memverses.where(:subsection => 2).first.verse.versenum).to eq(11)
    end

    it "should not subsection passages which have no information about ending verses" do
      psg = FactoryBot.create(:passage, book: 'Psalms', chapter: 22, first_verse: 13, last_verse: 22, length: 10)
      psg.auto_subsection
      expect(psg.memverses.first.subsection).to eq(0)
      expect(psg.memverses.last.subsection).to eq(0)
    end

    it "should handle nil subsection_end values gracefully" do
      # Use the same pattern as the other subsection tests - create passage in Psalms
      psg = FactoryBot.create(:passage, book: 'Psalms', chapter: 119, first_verse: 1, last_verse: 10, length: 10)
      
      # Ensure uberverses exist for this passage
      (1..10).each do |vs|
        Uberverse.find_or_create_by(book: 'Psalms', chapter: 119, versenum: vs, book_index: 19)
      end
      
      # Set all uberverses to have nil subsection_end values to simulate completely missing data
      Uberverse.where(book: 'Psalms', chapter: 119, versenum: 1..10).update_all(subsection_end: nil)
      
      # This should not raise an error (the main fix we're testing)
      expect { psg.auto_subsection }.not_to raise_error
      
      # The method should handle nil values gracefully without crashing
      # The specific behavior when all values are nil is to set subsection to 0
    end

  end

  # ==============================================================================================
  # Capture Supermemo data from underlying memory verses
  # ==============================================================================================
  it "should summarize Supermemo data from underlying memory verses" do

    # eFactor of these two verses is 2.0 as per factory
    # rep_n and interval are 4 and 5 respectively as per factory
    psg = FactoryBot.create(:passage, book: 'Nahum', chapter: 1, first_verse: 4, last_verse: 5, length: 2)

    # add an extra memory verse with a different eFactor
    # rep_n = 2, eFactor = 1.4, interval = 1
    vs = FactoryBot.create(:verse, book: 'Nahum', chapter: 1, versenum: 6)
    mv = FactoryBot.create(:memverse_without_supermemo_init, :verse => vs, :user => psg.user, :efactor => 1.4, :rep_n => 2, :test_interval => 3, :status => 'Learning')

    psg.expand( mv )
    psg.reload

    expect(psg.test_interval).to eq(3)
    expect(psg.rep_n).to eq(2)
    expect(psg.efactor.to_f).to eq(1.8)

  end

  # ==============================================================================================
  # Merge two passages into one (note: can be triggered by insertion of missing verse)
  # ==============================================================================================
  describe "combining two passages" do

    it "should merge two adjacent passages" do

      # Automatically generates user, memverses and verses through Factory
      psg1 = FactoryBot.create(:passage, user: @user, book: 'Luke', chapter: 2, first_verse: 2, last_verse: 4)
      psg2 = FactoryBot.create(:passage, user: @user, book: 'Luke', chapter: 2, first_verse: 5, last_verse: 8)

      expect {
        psg1.absorb( psg2 )
      }.to change(Passage, :count).by(-1)

      expect(psg1.first_verse).to eq(2)
      expect(psg1.last_verse).to eq(8)
      expect(psg1.book_index).to eq(42)
      expect(psg2.memverses.first.passage_id).to eq(psg1.id) # now associated with first passage

    end

    it "should merge two passages if linking verse is inserted" do

      # Automatically generates user, memverses and verses through Factory

      # Mark 2:2-4
      psg1 = FactoryBot.create(:passage, user: @user, book: 'Mark', chapter: 2, first_verse: 2, last_verse: 4, length: 3)
      # Mark 2:6-8
      psg2 = FactoryBot.create(:passage, user: @user, book: 'Mark', chapter: 2, first_verse: 6, last_verse: 8, length: 3)

      mv2 = psg2.memverses.first # need to ensure that this verse is associated with psg1 after combination

      # Mark 2:5
      vs = FactoryBot.create(:verse, book: 'Mark', chapter: 2, versenum: 5)
      mv = FactoryBot.create(:memverse, user: @user, verse: vs)  # triggers after_create call_back to add memory verse to passage

      psg1.reload
      mv2.reload

      # Assertions
      expect(psg1.first_verse).to eq(2)
      expect(psg1.last_verse).to eq(8)
      expect(psg1.length).to eq(7)
      expect(psg1.book_index).to eq(41)
      mv.passage_id           == psg1.id # link mv associated with first passage
      expect(mv2.passage_id).to eq(psg1.id) # now associated with first passage

    end

  end

  # ==============================================================================================
  # Add a memory verse to an existing passage
  # ==============================================================================================
  describe "add a new verse to a passage" do

    before(:each) do
      @psg = FactoryBot.create(:passage, :book => 'Leviticus', :chapter => 1, :first_verse => 3, :last_verse => 6)
    end

    it "should correctly add a preceding verse" do
      vs = FactoryBot.create(:verse, book: 'Leviticus', chapter: 1, versenum: 2)
      mv = FactoryBot.create(:memverse, verse: vs)

      @psg.expand( mv )

      expect(@psg.first_verse).to eq(2)
      expect(@psg.last_verse).to eq(6)
      expect(@psg.book_index).to eq(3)
      expect(mv.passage_id).to eq(@psg.id)
    end

    it "should correctly add a subsequent verse" do
      vs = FactoryBot.create(:verse, book: 'Leviticus', chapter: 1, versenum: 7)
      mv = FactoryBot.create(:memverse, verse: vs)

      @psg.expand( mv )

      expect(@psg.first_verse).to eq(3)
      expect(@psg.last_verse).to eq(7)
      expect(@psg.book_index).to eq(3)
      expect(mv.passage_id).to eq(@psg.id)
    end

  end

  # ==============================================================================================
  # Deleting memory verses from passage
  # ==============================================================================================
  describe "delete a memory verse from an existing passage" do

    before(:each) do
      @psg = FactoryBot.create(:passage, :book => 'Psalms', :chapter => 117, :first_verse => 1, :last_verse => 2)
    end

    it "should correctly delete the first verse of the passage" do
      mv = @psg.memverses.includes(:verse).order('verses.versenum').first
      mv.destroy

      expect(@psg.reload.length).to eq(1)
      expect(@psg.first_verse).to eq(2)
      expect(@psg.last_verse).to eq(2)
    end

    it "should correctly delete the last verse of the passage" do
      mv = @psg.memverses.includes(:verse).order('verses.versenum').last
      mv.destroy

      expect(@psg.reload.length).to eq(1)
      expect(@psg.first_verse).to eq(1)
      expect(@psg.last_verse).to eq(1)
    end

    it "should correctly delete a verse from the passage" do
      mv = @psg.memverses.includes(:verse).order('verses.versenum').first

      mv.destroy

      expect(@psg.reload.length).to eq(1)
      expect(@psg.first_verse).to eq(2)
      expect(@psg.last_verse).to eq(2)
      expect(@psg.reference).to eq("Psalm 117:2")
    end


    it "should correctly delete both verses from the passage" do
      mv1 = @psg.memverses.includes(:verse).order('verses.versenum').first
      mv2 = @psg.memverses.includes(:verse).order('verses.versenum').last

      mv1.destroy
      mv2.destroy

      # After deleting both verses, passage should no longer exist
      expect(Passage.find_by(id: @psg.id)).to be_nil
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

      psg = FactoryBot.create(:passage, user: @user, book: 'Esther', chapter: 10, first_verse: 1, last_verse: 2)
      vs = FactoryBot.create(:verse, book: 'Esther', chapter: 10, versenum: 3)
      mv = FactoryBot.create(:memverse, user: @user, verse: vs)

      expect(psg.complete_chapter).to be false
      psg.expand( mv )
      expect(psg.complete_chapter).to be true

    end

    it "should accept Psalms with a zero verse" do

      psg = FactoryBot.create(:passage, user: @user, book: 'Psalms', chapter: 53, first_verse: 0, last_verse: 5)
      vs  = FactoryBot.create(:verse, book: 'Psalms', chapter: 53, versenum: 6)
      mv  = FactoryBot.create(:memverse, user: @user, verse: vs)

      expect(psg.complete_chapter).to be false
      psg.expand( mv )
      expect(psg.complete_chapter).to be true

    end

    describe "should handle corner case of 3 John 1" do

      it "which has 14 verses in NIV" do
        psg = FactoryBot.create(:passage, user: @user, book: '3 John', chapter: 1, first_verse: 1, last_verse: 13, translation: 'NIV')
        vs = FactoryBot.create(:verse, book: '3 John', chapter: 1, versenum: 14)
        mv = FactoryBot.create(:memverse, user: @user, verse: vs)

        expect(psg.complete_chapter).to be false
        psg.expand( mv )
        expect(psg.complete_chapter).to be true
      end

      it "and 15 verses in ESV" do
        psg = FactoryBot.create(:passage, user: @user, book: '3 John', chapter: 1, first_verse: 1, last_verse: 14, translation: 'ESV')
        vs  = FactoryBot.create(:verse, book: '3 John', chapter: 1, versenum: 15)
        mv  = FactoryBot.create(:memverse, user: @user, verse: vs)

        expect(psg.complete_chapter).to be false
        psg.expand( mv )
        expect(psg.complete_chapter).to be true
      end

    end


  end

end
