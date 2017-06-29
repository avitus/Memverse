# encoding: utf-8
require 'spec_helper'

describe Verse do

  describe "category scope" do
    # verse    - Verse object
    # category - The Symbol for the category that the verse is supposed to
    #            exclusively belong to.
    def test_category(verse, category)

      categories = [:history, :wisdom, :prophecy, :gospel, :epistle]

      # verse should be in given category scope
      Verse.public_send(category).should include(verse)

      # verse should not be in any other category scope
      for category in categories - [category]
        Verse.public_send(category).should_not include(verse)
      end

    end

    describe "history" do
      it "includes Acts" do
        verse = FactoryGirl.create(:verse, book: "Acts", book_index: 44)

        test_category(verse, :history)
      end

      it "includes Genesis" do
        verse = FactoryGirl.create(:verse, book: "Genesis", book_index: 1)

        test_category(verse, :history)
      end
    end

    describe "wisdom" do
      it "includes Proverbs" do
        verse = FactoryGirl.create(:verse, book: "Proverbs", book_index: 20)

        test_category(verse, :wisdom)
      end
    end

    describe "prophecy" do
      it "includes Isaiah" do
        verse = FactoryGirl.create(:verse, book: "Isaiah", book_index: 23)

        test_category(verse, :prophecy)
      end
      it "includes Revelation" do
        verse = FactoryGirl.create(:verse, book: "Revelation", book_index: 66)

        test_category(verse, :prophecy)
      end
    end

    describe "gospel" do
      it "includes Mark" do
        verse = FactoryGirl.create(:verse, book: "Mark", book_index: 41)

        test_category(verse, :gospel)
      end
    end

    describe "epistle" do
      it "includes Ephesians" do
        verse = FactoryGirl.create(:verse, book: "Ephesians", book_index: 49)

        test_category(verse, :epistle)
      end
    end
  end

  describe "category methods" do
    describe ".prophecy?" do
      it "excludes non-prophecy" do
        genesis = FactoryGirl.create(:verse, book: "Genesis", book_index: 1)
        matthew = FactoryGirl.create(:verse, book: "Matthew", book_index: 40)

        genesis.prophecy? == false
        matthew.prophecy? == false
      end

      it "includes Isaiah to Malachi, and Revelation" do
        isaiah = FactoryGirl.create(:verse, book: "Isaiah", book_index: 23)
        revelation = FactoryGirl.create(:verse, book: "Revelation", book_index: 66)

        isaiah.prophecy? == true
        revelation.prophecy? == true
      end
    end
  end

  describe ".alternative_translations" do
    it "should include an alternative verse" do
      vs1 = FactoryGirl.create(:verse, book: "Philippians", book_index: 50, translation: "NKJV")
      vs2 = FactoryGirl.create(:verse, book: "Philippians", book_index: 50, translation: "ESV")

      vs1.alternative_translations.include?(vs2).should == true
    end
  end

  describe ".switch_tl" do
    it "should return correct verse" do
      vs1 = FactoryGirl.create(:verse, book: "Colossians", book_index: 51, translation: "NKJV")
      vs2 = FactoryGirl.create(:verse, book: "Colossians", book_index: 51, translation: "ESV")

      vs1.switch_tl("ESV").should == vs2
    end
  end

  it "should return correct mnemonic" do
    verse = FactoryGirl.create(:verse, :text => "This is an (extremely) important - mnemonic 'method' 'test'; don't you think?")
    verse.mnemonic.should == "T i a (e) i — m 'm' 't'; d y t?"
  end

  it "mnemonic method should support Portuguese" do
    verse = FactoryGirl.create(:verse, :text => "Á têst for mnémonic support of thé íncredíbly speciâl Portuguese çharacters.")
    verse.mnemonic.should == "Á t f m s o t í s P ç."
  end
  
  it "mnemonic method should support Korean" do
    verse = FactoryGirl.create(:verse, :text => "모든 사람이 죄를 범하였으매 하나님의 영광에 이르지 못하더니")
    verse.mnemonic.should == "ᄆᄃ ᄉᄅᄋ ᄌᄅ ᄇᄒᄋᄋᄆ ᄒᄂᄂᄋ ᄋᄀᄋ ᄋᄅᄌ ᄆᄒᄃᄂ"
  end

  it "should clean up the verse text" do
    verse = FactoryGirl.create(:verse, :text => "This is a \r\n \r\n \n test test   \n   teest. ")
	  verse.save!
    verse.text.should == "This is a test test teest."
  end

  it "should remove HTML tags (XSS prevention)" do
    verse = FactoryGirl.create(:verse, :text => "<script>test();</script>")
    verse.save!
    verse.text.should == "scripttest();/script"
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

      verse1.entire_chapter_available.should be false
    end

    it "should think a complete chapter is available" do
      final_verse = FactoryGirl.create(:final_verse, :book => "Psalms", :chapter => 117, :last_verse => 2)
      verse1 = FactoryGirl.create(:verse, :book => "Psalms", :chapter => 117, :versenum => 1)
      verse2 = FactoryGirl.create(:verse, :book => "Psalms", :chapter => 117, :versenum => 2)

      verse1.entire_chapter_available.should be true
    end
  end

  describe "validate ref" do
    before(:each) do
      @finalverse = FactoryGirl.create(:final_verse, :book => "Psalms", :chapter => 117, :last_verse => 2)
      # For these tests, Psalm 117 is the only valid chapter, and verse 2 is the last verse.
    end

    it "should prevent a duplicate verse" do

      expect { 
        FactoryGirl.create(:verse, book: "Psalms", book_index: 23, chapter: 117, versenum: 1, translation: "ESV")
        FactoryGirl.create(:verse, book: "Psalms", book_index: 23, chapter: 117, versenum: 1, translation: "ESV")
      }.to change { Verse.count }.by(1)

      # verse1 = FactoryGirl.build(:verse, :book => "Psalms", :chapter => 117, :versenum => 1)
      # verse2 = FactoryGirl.build(:verse, :book => "Psalms", :chapter => 117, :versenum => 1)
      # verse1.save.should be true
      # verse2.save.should be false
      # verse2.errors.full_messages.first.should == "Verse already exists in NIV"
    end

    it "should reject an invalid chapter" do

      expect { 
        Verse.create(book: "Psalms", chapter: 151, versenum: 1, translation: "ESV")
      }.not_to change { Verse.count }

      # verse = FactoryGirl.create(:verse, :book => "Psalms", :chapter => 151, :versenum => 1)
      # verse.save.should be false
      # verse.errors.full_messages.first.should == "Invalid chapter"
    end

    it "should reject an invalid versenum" do
      expect { 
        Verse.create(book: "Psalms", chapter: 117, versenum: 3, translation: "ESV")
      }.not_to change { Verse.count }
    end

      # verse = FactoryGirl.create(:verse, :book => "Psalms", :chapter => 117, :versenum => 3, :translation => "ESV")
  end

  describe "<=>" do
    it "should compare book first" do
      # if anything else is considered first, verse1 would precede verse2
      verse1 = FactoryGirl.create(:verse, book: "John", book_index: 43, chapter: 1, versenum: 1)
      verse2 = FactoryGirl.create(:verse, book: "Matthew", book_index: 40, chapter: 10, versenum: 10)

      (verse1 <=> verse2).should == 1
    end

    it "should compare chapter second" do
      # if versenum considered second, verse1 would precede verse2
      verse1 = FactoryGirl.create(:verse, book: "Matthew", book_index: 40, chapter: 11, versenum: 1)
      verse2 = FactoryGirl.create(:verse, book: "Matthew", book_index: 40, chapter: 10, versenum: 10)

      (verse1 <=> verse2).should == 1
    end

    it "should consider versenum third" do
      verse1 = FactoryGirl.create(:verse, book: "Matthew", book_index: 40, chapter: 10, versenum: 1)
      verse2 = FactoryGirl.create(:verse, book: "Matthew", book_index: 40, chapter: 10, versenum: 2)

      (verse1 <=> verse2).should == -1
    end

    it "should fall back on ID when all else identical" do
      verse1 = FactoryGirl.create(:verse, book: "Matthew", book_index: 40, chapter: 10, versenum: 1)
      verse2 = FactoryGirl.create(:verse, book: "Matthew", book_index: 40, chapter: 10, versenum: 0)

      verse2.stub(:versenum) { 1 } # two identical verses can't pass validations

      (verse1 <=> verse2).should == -1
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
