# encoding: utf-8
describe Verse do

  it "should return correct mnemonic" do
    verse = FactoryGirl.create(:verse, :text => "This is an (extremely) important - mnemonic 'method' 'test'; don't you think?")
    verse.mnemonic.should == "T i a (e) i - m 'm' 't'; d y t?"
  end

  it "mnemonic method should support Portuguese" do
    verse = FactoryGirl.create(:verse, :text => "Á têst for mnémonic support of thé íncredíbly speciâl Portuguese çharacters.")
    verse.mnemonic.should == "Á t f m s o t í s P ç."
  end

  it "should clean up the verse text" do
    verse = FactoryGirl.create(:verse, :text => "This is a \r\n \r\n \n test test   \n   teest. ")
	  verse.save!
    verse.text.should == "This is a test test teest."
  end

  describe "entire_chapter_available" do
    it "should not think an incomplete chapter is available" do
      final_verse = FactoryGirl.create(:final_verse, :book => "Psalms", :chapter => 117, :last_verse => 2)
      verse1 = FactoryGirl.create(:verse, :book => "Psalms", :chapter => 117, :versenum => 1)

      verse1.entire_chapter_available.should be_false
    end

    it "should think a complete chapter is available" do
      final_verse = FactoryGirl.create(:final_verse, :book => "Psalms", :chapter => 117, :last_verse => 2)
      verse1 = FactoryGirl.create(:verse, :book => "Psalms", :chapter => 117, :versenum => 1)
      verse2 = FactoryGirl.create(:verse, :book => "Psalms", :chapter => 117, :versenum => 2)

      verse1.entire_chapter_available.should be_true
    end
  end

  describe "validate ref" do
    before(:each) do
      @finalverse = FactoryGirl.create(:final_verse, :book => "Psalms", :chapter => 117, :last_verse => 2)
      # For these tests, Psalm 117 is the only valid chapter, and verse 2 is the last verse.
    end

    it "should prevent a duplicate verse" do
      verse1 = FactoryGirl.build(:verse, :book => "Psalms", :chapter => 117, :versenum => 1).should be_valid
      verse2 = FactoryGirl.build(:verse, :book => "Psalms", :chapter => 117, :versenum => 1).should_not be_valid

      verse2.errors.full_messages.first.should == "Verse already exists in NIV"
    end

    it "should reject an invalid chapter" do
      verse = FactoryGirl.build(:verse_with_validate_ref, :book => "Psalms", :chapter => 151, :versenum => 1)
      verse.save.should be_false
      verse.errors.full_messages.first.should == "Invalid chapter"
    end

    it "should reject an invalid versenum" do
      verse = FactoryGirl.build(:verse_with_validate_ref, :book => "Psalms", :chapter => 117, :versenum => 3, :translation => "ESV")
      verse.save.should be_false
      verse.errors.full_messages.first.should == "Invalid verse number"
    end
  end

describe "web_check" do
  it "confirm that text of Psalm 35:1 KJV matches on Bible Gateway" do
    verse = FactoryGirl.create(:verse, :book_index => 19, :book => "Psalms", :chapter => 35, :versenum => 1, :translation => "KJV",
                               :text => "Plead my cause, O Lord, with them that strive with me: fight against them that fight against me.")
    verse.web_check == true
  end
end

end
