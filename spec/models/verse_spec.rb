# encoding: utf-8
describe Verse do

  it "should return correct mnemonic" do
    verse = FactoryGirl.create(:verse, :text => "This is an (extremely) important - mnemonic 'method' 'test'; don't you think?")
    verse.mnemonic.should == "T i a (e) i — m 'm' 't'; d y t?"
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

  it "should use em dashes when appropriate" do
    verse1 = FactoryGirl.create(:verse, :versenum => 1, :text => "This is a test -")
    verse1.save!
    verse1.text.should == "This is a test —"

    verse2 = FactoryGirl.create(:verse, :versenum => 2, :text => "- which was a test")
    verse2.save!
    verse2.text.should == "— which was a test"

    verse3 = FactoryGirl.create(:verse, :versenum => 3, :text => "This is a hyphenated-word")
    verse3.save!
    verse3.text.should == "This is a hyphenated-word"

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
      verse1 = FactoryGirl.build(:verse_with_validate_ref, :book => "Psalms", :chapter => 117, :versenum => 1)
      verse2 = FactoryGirl.build(:verse_with_validate_ref, :book => "Psalms", :chapter => 117, :versenum => 1)
      verse1.save.should be_true
      verse2.save.should be_false
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


  # ==============================================================================================
  # Spec for BibleGateway API
  # ==============================================================================================
  describe "web_check" do
    it "should say the verse matches in the database" do
      verse = FactoryGirl.create(:verse, :book => "John", :chapter => 3, :versenum => 16, :translation => "NNV", :text => "For God so loved the world that he gave his one and only Son, that whoever believes in him shall not perish but have eternal life.")
      verse.database_text.should == "For God so loved the world that he gave his one and only Son, that whoever believes in him shall not perish but have eternal life."
    end

    it "should say normal verses match on Bible Gateway" do
      verse = FactoryGirl.create(:verse, :book => "John", :chapter => 3, :versenum => 16, :translation => "KJV", :text => "For God so loved the world, that he gave his only begotten Son, that whosoever believeth in him should not perish, but have everlasting life.")
      verse.database_text.should == "For God so loved the world, that he gave his only begotten Son, that whosoever believeth in him should not perish, but have everlasting life."
      verse.web_text.should == verse.database_text
    end

    it "should say the first verses of chapters match on Bible Gateway" do
      verse = FactoryGirl.create(:verse, :book => "Genesis", :chapter => 1, :versenum => 1, :translation => "KJV", :text => "In the beginning God created the heaven and the earth.")
      verse.database_text == "In the beginning God created the heaven and the earth."
      verse.web_text.should == verse.database_text
    end

    it "should say poetry verses match on Bible Gateway" do
      verse = FactoryGirl.create(:verse, :book => "Psalms", :chapter => 35, :versenum => 2, :translation => "NNV", :text => "Take up shield and armor; arise and come to my aid.")
      verse.database_text.should == "Take up shield and armor; arise and come to my aid."
      verse.web_text.should == verse.database_text
    end

    it "should say verses with 'LORD' in them match on Bible Gateway" do
      verse = FactoryGirl.create(:verse, :book => "Hosea", :chapter => 14, :versenum => 2, :translation => "NNV", :text => 'Take words with you and return to the LORD. Say to him: “Forgive all our sins and receive us graciously, that we may offer the fruit of our lips.')
      verse.database_text.should == 'Take words with you and return to the LORD. Say to him: "Forgive all our sins and receive us graciously, that we may offer the fruit of our lips.'
      verse.web_text.should == verse.database_text
    end

    it "should say verses with all of the above exceptions together match on Bible Gateway" do
      verse = FactoryGirl.create(:verse, :book => "Psalms", :chapter => 9, :versenum => 1, :translation => "NNV", :text => "I will give thanks to you, LORD, with all my heart; I will tell of all your wonderful deeds.")
      verse.database_text.should == "I will give thanks to you, LORD, with all my heart; I will tell of all your wonderful deeds."
      verse.web_text.should == verse.database_text
    end


    it "should say incorrect verses are incorrect" do
      verse = FactoryGirl.create(:verse, :book => "Psalms", :chapter => 35, :versenum => 3, :translation => "NNV", :text => "This is incorrect")
      verse.database_text.should_not == "Brandish spear and javelin against those who pursue me.  Say to my soul, “I am your salvation.”"
      verse.web_text.should_not == verse.database_text
    end
  end

end
