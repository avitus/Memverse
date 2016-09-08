require 'spec_helper'

describe MemversesController do

  before (:each) do
    @user = FactoryGirl.create(:user)
    @user.confirm
    sign_in @user

    @verse = FactoryGirl.create(:verse)

  end

  # See passage controller for how to create a default set of attributes

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # MemversesController. Be sure to keep this updated too.
  def valid_session
    { "warden.user.user.key" => session["warden.user.user.key"] }
  end

  describe "GET 'ajax_add'" do

    it "should allow a user to add a verse" do
      get :ajax_add, { :id => @verse }, valid_session
      @user.memverses.first.verse.should == @verse
    end

    it "should not allow the identical verse to be added twice" do
      get :ajax_add, { :id => @verse }, valid_session
      get :ajax_add, { :id => @verse }, valid_session
      @user.memverses.count.should == 1
    end

    it "should not allow the same verse in two different translations" do
      @verse_kjv = FactoryGirl.create(:verse, :translation => 'KJV')
      @verse_esv = FactoryGirl.create(:verse, :translation => 'ESV')
      get :ajax_add, { :id => @verse_kjv }, valid_session
      get :ajax_add, { :id => @verse_esv }, valid_session
      @user.memverses.count.should == 1
    end

  end

  describe "POST 'add_chapter'" do

    before (:each) do
      @chapter = Array.new
      for i in 1..5
        verse       = FactoryGirl.create(:verse, :book_index => 19, :book => "Psalms", :chapter => '15', :versenum => i, :translation => "NIV")
        @chapter[i] = FactoryGirl.create(:memverse, :user => @user, :verse => verse)
      end
    end

    # TODO: these tests aren't really testing the controller functionality since they don't actually call any methods

    it "should add an entire chapter to users memory verses" do
      # get :add_chapter, :bk => "Psalms", :ch => 15, :tl => "NIV"
      @user.memverses.count.should == 5
    end

    it "should correctly link the verses to the first verse" do
      # get :add_chapter, :bk => "Psalms", :ch => 15, :tl => "NIV"
      first_verse = @user.memverses.includes(:verse).where('verses.versenum' => 1).first
      third_verse = @user.memverses.includes(:verse).where('verses.versenum' => 3).first
      third_verse.first_verse.should == first_verse.id
    end

    it "should correctly link a verse to the previous verse" do
      # get :add_chapter, :bk => "Psalms", :ch => 15, :tl => "NIV"
      fourth_verse = @user.memverses.includes(:verse).where('verses.versenum' => 4).first
      fifth_verse  = @user.memverses.includes(:verse).where('verses.versenum' => 5).first
      fifth_verse.prev_verse.should == fourth_verse.id
    end

    it "should correctly link a verse to the next verse" do
      # get :add_chapter, :bk => "Psalms", :ch => 15, :tl => "NIV"
      fourth_verse = @user.memverses.includes(:verse).where('verses.versenum' => 4).first
      fifth_verse  = @user.memverses.includes(:verse).where('verses.versenum' => 5).first
      fourth_verse.next_verse.should == fifth_verse.id
    end

  end

  describe "GET 'mv_lookup_passage'" do 
    it "should retrieve verses in a given passage" do
      get :mv_lookup_passage, :bk => "Psalms", :ch => 1, valid_session
      response.should be_success
    end

    it "should reject out of range chapters" do
      get :mv_lookup_passage, :bk => "Psalms", :ch => 200, valid_session
      response.should be_success
    end

    it "should reject out of range verse numbers" do
      get :mv_lookup_passage, :bk => "Psalms", :ch => 1, :vs_start => 1, :vs_end => 100, valid_session
      response.should be_success
    end

  end

end
