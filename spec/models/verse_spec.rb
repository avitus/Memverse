# encoding: utf-8
describe Verse do

  it "should return correct mnemonic" do
    verse = Factory(:verse, :text => "This is an (extremely) important - mnemonic 'method' 'test'; don't you think?")
    verse.mnemonic.should == "T i a (e) i - m 'm' 't'; d y t?"
  end
  
  it "mnemonic method should support Portuguese" do
    verse = Factory(:verse, :text => "Á têst for mnémonic support of thé íncredíbly speciâl Portuguese çharacters.")
    verse.mnemonic.should == "Á t f m s o t í s P ç."
  end
  
  it "should clean up the verse text" do
    verse = Factory(:verse, :text => "This is a \r\n \r\n \n test test   \n   teest. ")
	  verse.save!
    verse.text.should == "This is a test test teest."
  end
  
  describe "entire_chapter_available" do
    it "should not think an incomplete chapter is available" do
      final_verse = Factory(:final_verse, :book => "Psalms", :chapter => 117, :last_verse => 2)
      verse1 = Factory(:verse, :book => "Psalms", :chapter => 117, :versenum => 1)
      
      verse1.entire_chapter_available.should be_false
    end
    
    it "should think a complete chapter is available" do
      final_verse = Factory(:final_verse, :book => "Psalms", :chapter => 117, :last_verse => 2)
      verse1 = Factory(:verse, :book => "Psalms", :chapter => 117, :versenum => 1)
      verse2 = Factory(:verse, :book => "Psalms", :chapter => 117, :versenum => 2)
      
      verse1.entire_chapter_available.should be_true
    end
  end
  
  describe "validate ref" do
    before(:each) do
      @finalverse = Factory(:final_verse, :book => "Psalms", :chapter => 117, :last_verse => 2)
      # For these tests, Psalm 117 is the only valid chapter, and verse 2 is the last verse.
    end
    
    it "should prevent a duplicate verse" do
      verse1 = Factory.build(:verse, :book => "Psalms", :chapter => 117, :versenum => 1)
      verse2 = Factory.build(:verse, :book => "Psalms", :chapter => 117, :versenum => 1)
      
      verse1.save.should be_true
      verse2.save.should be_false
      verse2.errors.full_messages.first.should == "Verse already exists in NIV"
    end
    
    it "should reject an invalid chapter" do
      verse = Factory.build(:verse, :book => "Psalms", :chapter => 151, :versenum => 1)
      verse.save.should be_false
       verse.errors.full_messages.first.should == "Invalid chapter"
    end
    
    it "should reject an invalid versenum" do
      verse = Factory.build(:verse, :book => "Psalms", :chapter => 117, :versenum => 3, :translation => "ESV")
      verse.save.should be_false
      verse.errors.full_messages.first.should == "Invalid verse number"
    end
  end
  
end
