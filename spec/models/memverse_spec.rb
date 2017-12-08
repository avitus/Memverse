require 'spec_helper'

describe Memverse do

  before(:each) do
    @user  = User.create!(:name => "Test User", :email => "test@memverse.com", :password => "secret", :password_confirmation => "secret")
  end

  #  --------------------------------------------------------------------------------------------------------------
  #  The after_create hooks don't seem to be called so testing this functionality in the controller for now.
  #  Would prefer to have it at the model level, though
  #  --------------------------------------------------------------------------------------------------------------
  it "should create a new instance given a valid attribute" do
    @verse = Verse.create!(:book_index => 1, :book => "Genesis", :chapter => 12, :versenum => 1, :text => "This is a test", :translation => "NIV")
    Memverse.create!(:user => @user, :verse => @verse)
  end


  #  --------------------------------------------------------------------------------------------------------------
  #  All functionality for synchronizing subsectioned verses
  #  --------------------------------------------------------------------------------------------------------------
  describe "Synchronize subsections" do

    before(:each) do

      @passage = Array.new
      @sync_u  = FactoryBot.create(:user, sync_subsections: true)

      for i in 1..10
        verse       = FactoryBot.create(:verse, book_index: 19, book: "Psalms", chapter: 24, versenum: i, text: "This is a test")

        # Create two subsections a) 1-6 and b) 7-10
        if i<=6
          if i<=1 # Verse 1 is not due
            @passage[i] = FactoryBot.create(:memverse_without_supermemo_init, user: @sync_u, verse: verse, subsection: 0,
                                              test_interval: i, next_test: Date.today + i, last_tested: Date.today - 2.weeks)
          else    # Verses 2-6 are due
            @passage[i] = FactoryBot.create(:memverse_without_supermemo_init, user: @sync_u, verse: verse, subsection: 0,
                                              test_interval: i, next_test: Date.today - i, last_tested: Date.today - 2.weeks)
          end
          # puts @passage[i].inspect
        else
          @passage[i] = FactoryBot.create(:memverse_without_supermemo_init, user: @sync_u, verse: verse, subsection: 1,
                                            test_interval: i, next_test: Date.today - i, last_tested: Date.today - 2.weeks)
        end

      end

    end

    it "should set the next test date to be the same for all verses in a subsection that were tested today" do
      @passage[2].supermemo(5)
      @passage[3].supermemo(4)
      @passage[4].supermemo(3)

      for i in 1..6
        @passage[i].reload
      end

      @passage[3].next_test.should         == @passage[1].next_test # Synchronize this verse which isn't due
      @passage[3].next_test.should         == @passage[2].next_test
      @passage[3].next_test.should         == @passage[3].next_test
      @passage[3].next_test.should         == @passage[4].next_test
      @passage[3].next_test.should_not     == @passage[5].next_test # Don't synchronize with verses that have not yet been tested
      @passage[3].next_test.should_not     == @passage[6].next_test # Don't synchronize with verses that have not yet been tested

    end

     it "should set the interval to be the same for all verses in a subsection that were tested today" do
      @passage[2].supermemo(5)
      @passage[3].supermemo(4)
      @passage[4].supermemo(3)

      for i in 1..6
        @passage[i].reload
      end

      @passage[3].test_interval.should     == @passage[1].test_interval # Synchronize this verse which isn't due
      @passage[3].test_interval.should     == @passage[2].test_interval
      @passage[3].test_interval.should     == @passage[3].test_interval
      @passage[3].test_interval.should     == @passage[4].test_interval
      @passage[3].test_interval.should_not == @passage[5].test_interval # Don't synchronize with verses that have not yet been tested
      @passage[3].test_interval.should_not == @passage[6].test_interval # Don't synchronize with verses that have not yet been tested
    end

  end

  #  --------------------------------------------------------------------------------------------------------------
  #  Link adjacent verses into passages
  #  --------------------------------------------------------------------------------------------------------------
  describe "Verse Linking" do

    before(:each) do

      @passage = Array.new

      for i in 1..6
        verse       = Verse.create(:book_index => 19, :book => "Psalms", :chapter => 8, :versenum => i, :text => "This is a test")
        @passage[i] = Memverse.create(:user => @user, :verse => verse)
      end

    end

    it "should link a new verse to the following verse" do
      @passage[2].next_verse.should  == @passage[3].id
    end

    it "should link a new verse to the previous verse" do
      @passage[2].prev_verse.should  == @passage[1].id
    end

    it "should link the following verse to the new verse" do
      @passage[3].prev_verse.should  == @passage[2].id
    end

    it "should link the previous verse to the new verse" do
      @passage[1].next_verse.should  == @passage[2].id
    end

    it "should point the new verse to the first verse" do
      @passage[2].first_verse.should == @passage[1].id
    end

    it "should not point the first verse to anything" do
      @passage[1].first_verse.should be_nil
    end

  end

  describe ".next_verse_due" do
    before(:each) do

      @passage = Array.new

      for i in 1..6
        verse       = FactoryBot.create(:verse, book_index: 20, book: "Proverbs", chapter: 1, versenum: i, text: "This is a test")
        @passage[i] = FactoryBot.create(:memverse, user: @user, verse: verse)
      end

      @passage[1].next_test = Date.tomorrow
      @passage[1].save

      for i in 1..6
        @passage[i].reload # due to after_create verse linkage
      end
    end

    describe "(skip=false)" do
      it "should return next verse in passage" do
        @passage[1].next_verse_due(false).should == @passage[2]
      end

      it "should ignore subsequent due pending verse" do
        @passage[2].update_column(:status, "Pending")

        @passage[1].next_verse_due(false).should == @passage[3]
      end

      it "should ignore subsequent undue pending verse" do
        @passage[2].update_column(:status, "Pending")
        @passage[2].update_column(:next_test, Date.tomorrow)

        @passage[1].next_verse_due(false).should == @passage[3]
      end

      it "should return next due verse (no passage)" do
        @passage[6].next_verse_due(false).should == @passage[1]
      end
    end

    describe "(skip=true)" do
      it "should return next due verse in passage" do
        @passage[2].update_column(:next_test, Date.tomorrow)

        @passage[2].status.should == "Learning" # sanity check
        @passage[1].next_verse_due(true).should == @passage[3]
      end

      it "should ignore pending verse" do
        @passage[2].update_column(:status, "Pending")

        @passage[2].next_test.should == Date.today # sanity check
        @passage[1].next_verse_due(true).should == @passage[3]
      end

      it "should return next due verse (no passage)" do
        @passage[6].next_verse_due(true).should == @passage[1]
      end
    end
  end

end
