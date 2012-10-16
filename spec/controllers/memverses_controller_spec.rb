require 'spec_helper'

describe MemversesController do
  
  before (:each) do
    @user = FactoryGirl.create(:user)
    @user.confirm!
    sign_in @user
    
    @verse = FactoryGirl.create(:verse)
    
  end
  
  describe "GET 'ajax_add'" do
    
    it "should allow a user to add a verse" do
      get :ajax_add, :id => @verse
      @user.memverses.first.verse.should == @verse
    end
    
    it "should not allow the identical verse to be added twice" do
      get :ajax_add, :id => @verse
      get :ajax_add, :id => @verse
      @user.memverses.count.should == 1      
    end
    
    it "should not allow the same verse in two different translations" do
      @verse_kjv = FactoryGirl.create(:verse, :translation => 'KJV')
      @verse_esv = FactoryGirl.create(:verse, :translation => 'ESV')
      get :ajax_add, :id => @verse_kjv
      get :ajax_add, :id => @verse_esv
      @user.memverses.count.should == 1            
    end
    
  end
  
  describe "GET 'add_chapter'" do
    
    before (:each) do
      @chapter = Array.new         
      for i in 1..5
        verse       = FactoryGirl.create(:verse, :book_index => 19, :book => "Psalms", :chapter => '15', :versenum => i, :translation => "NIV")
        @chapter[i] = FactoryGirl.create(:memverse, :user => @user, :verse => verse)
      end        
    end
     
    it "should add an entire chapter to users memory verses" do
      get :add_chapter, :bk => "Psalms", :ch => 15, :tl => "NIV"
      @user.memverses.count.should == 5
    end
    
    it "should correctly link the verses to the first verse" do 
      get :add_chapter, :bk => "Psalms", :ch => 15, :tl => "NIV"
      first_verse = @user.memverses.includes(:verse).where('verses.versenum' => 1).first  
      third_verse = @user.memverses.includes(:verse).where('verses.versenum' => 3).first
      third_verse.first_verse.should == first_verse.id
    end

    it "should correctly link a verse to the previous verse" do 
      get :add_chapter, :bk => "Psalms", :ch => 15, :tl => "NIV"
      fourth_verse = @user.memverses.includes(:verse).where('verses.versenum' => 4).first  
      fifth_verse  = @user.memverses.includes(:verse).where('verses.versenum' => 5).first
      fifth_verse.prev_verse.should == fourth_verse.id
    end

    it "should correctly link a verse to the next verse" do 
      get :add_chapter, :bk => "Psalms", :ch => 15, :tl => "NIV"
      fourth_verse = @user.memverses.includes(:verse).where('verses.versenum' => 4).first  
      fifth_verse  = @user.memverses.includes(:verse).where('verses.versenum' => 5).first
      fourth_verse.next_verse.should == fifth_verse.id
    end
  
  end
  
  
end
