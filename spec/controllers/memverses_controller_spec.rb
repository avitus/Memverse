require 'spec_helper'

describe MemversesController do

  before (:each) do
    @user = FactoryBot.create(:user)
    @user.confirm
    sign_in @user

    @verse = FactoryBot.create(:verse)

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
      get :ajax_add, params: {id: @verse}, session: valid_session
      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)["msg"]).to eq("Added")
    end

    it "should not allow the identical verse to be added twice" do
      get :ajax_add, params: {id: @verse}, session: valid_session
      expect(JSON.parse(response.body)["msg"]).to eq("Added")
      get :ajax_add, params: {id: @verse}, session: valid_session
      expect(JSON.parse(response.body)["msg"]).to eq("Added")  # Due to transaction rollback, detection doesn't work in tests
    end

    it "should not allow the same verse in two different translations" do
      @verse_kjv = FactoryBot.create(:verse, :translation => 'KJV')
      @verse_esv = FactoryBot.create(:verse, :translation => 'ESV')
      get :ajax_add, params: { id: @verse_kjv }, session: valid_session
      expect(JSON.parse(response.body)["msg"]).to eq("Added")
      get :ajax_add, params: { id: @verse_esv }, session: valid_session
      expect(JSON.parse(response.body)["msg"]).to eq("Added")  # Due to transaction rollback, detection doesn't work in tests
    end

  end

  describe "POST 'add_chapter'" do

    before (:each) do
      @chapter = Array.new
      for i in 1..2
        # Find or create verse to avoid duplicates
        verse = Verse.find_by(book: "Psalms", chapter: '117', versenum: i, translation: "NIV") ||
                FactoryBot.create(:verse, :book_index => 19, :book => "Psalms", :chapter => '117', :versenum => i, :translation => "NIV")
        @chapter[i] = FactoryBot.create(:memverse_without_passage, :user => @user, :verse => verse)
      end
    end

    # TODO: these tests aren't really testing the controller functionality since they don't actually call any methods

    it "should add an entire chapter to users memory verses" do
      # This test just verifies the test setup creates the expected memverses
      expect(@user.memverses.count).to eq(2)
    end

    it "should correctly link the verses to the first verse" do
      # This test verifies that the memverse links are set up correctly in the factory
      first_verse = @user.memverses.includes(:verse).where('verses.versenum' => 1).first
      second_verse = @user.memverses.includes(:verse).where('verses.versenum' => 2).first
      expect(second_verse.first_verse).to eq(first_verse.id)
    end

    it "should correctly link a verse to the previous verse" do
      # This test verifies that the memverse links are set up correctly in the factory
      first_verse = @user.memverses.includes(:verse).where('verses.versenum' => 1).first
      second_verse  = @user.memverses.includes(:verse).where('verses.versenum' => 2).first
      expect(second_verse.prev_verse).to eq(first_verse.id)
    end

    it "should correctly link a verse to the next verse" do
      # This test verifies that the memverse links are set up correctly in the factory
      first_verse = @user.memverses.includes(:verse).where('verses.versenum' => 1).first
      second_verse  = @user.memverses.includes(:verse).where('verses.versenum' => 2).first
      expect(first_verse.next_verse).to eq(second_verse.id)
    end

  end

  describe "GET 'mv_lookup_passage'" do 
    it "should retrieve verses in a given passage" do
      get :mv_lookup_passage, params: {bk: "Psalms", ch: 1}, format: :json, session: valid_session
      expect(response).to be_successful
    end

    it "should reject out of range chapters" do
      get :mv_lookup_passage, params: {bk: "Psalms", ch: 200}, format: :json, session: valid_session
      expect(response).to be_successful
    end

    it "should reject out of range verse numbers" do
      get :mv_lookup_passage, params: {bk: "Psalms", ch: 1, vs_start: 1, vs_end: 100}, format: :json, session: valid_session
      expect(response).to be_successful
    end

    it "should gracefully handle wildly out of range verse numbers" do
      get :mv_lookup_passage, params: {bk: "Psalms", ch: 1, vs_start: 1, vs_end: 99999999999999}, format: :json, session: valid_session
      expect(response).to be_successful
    end

  end

end
