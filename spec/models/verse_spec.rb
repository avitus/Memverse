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
      expect(Verse.public_send(category)).to include(verse)

      # verse should not be in any other category scope
      for category in categories - [category]
        expect(Verse.public_send(category)).not_to include(verse)
      end

    end

    describe "history" do
      it "includes Acts" do
        verse = FactoryBot.create(:verse, book: "Acts", book_index: 44)

        test_category(verse, :history)
      end

      it "includes Joshua" do
        verse = FactoryBot.create(:verse, book: "Joshua", book_index: 6)

        test_category(verse, :history)
      end
    end

    describe "wisdom" do
      it "includes Psalms" do
        verse = FactoryBot.create(:verse, book: "Psalms", book_index: 19)

        test_category(verse, :wisdom)
      end
    end

    describe "prophecy" do
      it "includes Isaiah" do
        verse = FactoryBot.create(:verse, book: "Isaiah", book_index: 23)

        test_category(verse, :prophecy)
      end
      it "includes Revelation" do
        verse = FactoryBot.create(:verse, book: "Revelation", book_index: 66, versenum: 2)

        test_category(verse, :prophecy)
      end
    end

    describe "gospel" do
      it "includes Mark" do
        verse = FactoryBot.create(:verse, book: "Mark", book_index: 41)

        test_category(verse, :gospel)
      end
    end

    describe "epistle" do
      it "includes Ephesians" do
        verse = FactoryBot.create(:verse, book: "Ephesians", book_index: 49)

        test_category(verse, :epistle)
      end
    end
  end

  describe "category methods" do
    describe ".prophecy?" do
      it "excludes non-prophecy" do
        psalms = FactoryBot.create(:verse, book: "Psalms", book_index: 19)
        matthew = FactoryBot.create(:verse, book: "Matthew", book_index: 40, versenum: 2)

        expect(psalms.prophecy?).to be false
        expect(matthew.prophecy?).to be false
      end

      it "includes Isaiah to Malachi, and Revelation" do
        isaiah = FactoryBot.create(:verse, book: "Isaiah", book_index: 23, versenum: 1)
        malachi = FactoryBot.create(:verse, book: "Malachi", book_index: 39, versenum: 1)
        revelation = FactoryBot.create(:verse, book: "Revelation", book_index: 66, versenum: 2)

        expect(isaiah.prophecy?).to be true
        expect(malachi.prophecy?).to be true
        expect(revelation.prophecy?).to be true
      end
    end
  end

  describe ".alternative_translations" do
    it "should include an alternative verse" do
      vs1 = FactoryBot.create(:verse, book: "Psalms", book_index: 19, chapter: 117, versenum: 1, translation: "NKJV")
      vs2 = FactoryBot.create(:verse, book: "Psalms", book_index: 19, chapter: 117, versenum: 1, translation: "ESV")

      expect(vs1.alternative_translations.include?(vs2)).to eq(true)
    end
  end

  describe ".switch_tl" do
    it "should return correct verse" do
      vs1 = FactoryBot.create(:verse, book: "Psalms", book_index: 19, chapter: 117, versenum: 2, translation: "NKJV")
      vs2 = FactoryBot.create(:verse, book: "Psalms", book_index: 19, chapter: 117, versenum: 2, translation: "ESV")

      expect(vs1.switch_tl("ESV")).to eq(vs2)
    end
  end

  it "should return correct mnemonic" do
    verse = FactoryBot.create(:verse, :text => "This is an (extremely) important - mnemonic 'method' 'test'; don't you think?")
    expect(verse.mnemonic).to eq("T i a (e) i — m 'm' 't'; d y t?")
  end

  it "mnemonic method should support Portuguese" do
    verse = FactoryBot.create(:verse, :text => "Á têst for mnémonic support of thé íncredíbly speciâl Portuguese çharacters.")
    expect(verse.mnemonic).to eq("Á t f m s o t í s P ç.")
  end
  
  it "mnemonic method should support Korean" do
    verse = FactoryBot.create(:verse, :text => "모든 사람이 죄를 범하였으매 하나님의 영광에 이르지 못하더니")
    expect(verse.mnemonic).to eq("ᄆᄃ ᄉᄅᄋ ᄌᄅ ᄇᄒᄋᄋᄆ ᄒᄂᄂᄋ ᄋᄀᄋ ᄋᄅᄌ ᄆᄒᄃᄂ")
  end

  it "should clean up the verse text" do
    verse = FactoryBot.create(:verse, versenum: 2, text: "This is a \r\n \r\n \n test test   \n   teest. ")
    expect(verse.text).to eq("This is a test test teest.")
  end

  it "should remove HTML tags (XSS prevention)" do
    verse = FactoryBot.create(:verse, versenum: 1, translation: "KJV", text: "<script>test();</script>")
    expect(verse.text).to eq("scripttest();/script")
  end

  it "should use em dashes when appropriate" do
    verse1 = FactoryBot.create(:verse, versenum: 1, translation: "NIV", text: "This is a test -")
    expect(verse1.text).to eq("This is a test —")

    verse2 = FactoryBot.create(:verse, versenum: 2, translation: "NIV", text: "- which was a test")
    expect(verse2.text).to eq("— which was a test")

    verse3 = FactoryBot.create(:verse, versenum: 1, translation: "ESV", text: "This is a hyphenated-word")
    expect(verse3.text).to eq("This is a hyphenated-word")

  end

  describe "entire_chapter_available" do
    it "should not think an incomplete chapter is available" do
      final_verse = FactoryBot.create(:final_verse, book: "Psalms", chapter: 117, last_verse: 2)
      verse1 = FactoryBot.create(:verse, book: "Psalms", chapter: 117, versenum: 1)

      expect(verse1.entire_chapter_available).to be false
    end

    it "should think a complete chapter is available" do
      final_verse = FactoryBot.create(:final_verse, :book => "Psalms", :chapter => 117, :last_verse => 2)
      verse1 = FactoryBot.create(:verse, :book => "Psalms", :chapter => 117, :versenum => 1)
      verse2 = FactoryBot.create(:verse, :book => "Psalms", :chapter => 117, :versenum => 2)

      expect(verse1.entire_chapter_available).to be true
    end
  end

  describe "validate ref" do
    before(:each) do
      @finalverse = FactoryBot.create(:final_verse, :book => "Psalms", :chapter => 117, :last_verse => 2)
      # For these tests, Psalm 117 is the only valid chapter, and verse 2 is the last verse.
    end

    it "should reject an invalid chapter" do

      expect { 
        Verse.create(book: "Psalms", chapter: 151, versenum: 1, translation: "ESV")
      }.not_to change { Verse.count }

      # verse = FactoryBot.create(:verse, :book => "Psalms", :chapter => 151, :versenum => 1)
      # verse.save.should be false
      # verse.errors.full_messages.first.should eq("Invalid chapter")
    end

    it "should reject an invalid versenum" do
      expect { 
        Verse.create(book: "Psalms", chapter: 117, versenum: 2, translation: "ESV")
      }.not_to change { Verse.count }
    end

      # verse = FactoryBot.create(:verse, :book => "Psalms", :chapter => 117, :versenum => 3, :translation => "ESV")
  end

  describe "<=>" do
    it "should compare book first" do
      # if anything else is considered first, verse1 would precede verse2
      verse1 = FactoryBot.create(:verse, book: "Psalms", book_index: 19, chapter: 117, versenum: 1)
      verse2 = FactoryBot.create(:verse, book: "Psalms", book_index: 19, chapter: 117, versenum: 2)

      expect((verse1 <=> verse2)).to eq(-1)
    end

    it "should compare chapter second" do
      # if versenum considered second, verse1 would precede verse2
      verse1 = FactoryBot.create(:verse, book: "Psalms", book_index: 19, chapter: 117, versenum: 2)
      verse2 = FactoryBot.create(:verse, book: "Psalms", book_index: 19, chapter: 117, versenum: 1)

      expect((verse1 <=> verse2)).to eq(1)
    end

    it "should consider versenum third" do
      verse1 = FactoryBot.create(:verse, book: "Matthew", book_index: 40, chapter: 10, versenum: 1)
      verse2 = FactoryBot.create(:verse, book: "Matthew", book_index: 40, chapter: 10, versenum: 2)

      expect((verse1 <=> verse2)).to eq(-1)
    end

    it "should fall back on ID when all else identical" do
      verse1 = FactoryBot.create(:verse, book: "Matthew", book_index: 40, chapter: 10, versenum: 1)
      verse2 = FactoryBot.create(:verse, book: "Matthew", book_index: 40, chapter: 10, versenum: 0)

      allow(verse2).to receive(:versenum) { 1 } # two identical verses can't pass validations

      expect((verse1 <=> verse2)).to eq(-1)
    end
  end

  # web_text normalizes what BibleGateway returns so it can be compared with database_text.
  # The scraper itself is covered by spec/lib/bible_gateway_spec.rb; no network here.
  describe "web_check" do
    let(:verse) do
      FactoryBot.create(:verse, book: "Psalms", chapter: 117, versenum: 1, translation: "NNV",
                                text: 'Praise the LORD, all you nations; extol him, all you "peoples".')
    end

    def bible_gateway_returns(content)
      gateway = instance_double(BibleGateway, lookup: { content: content })
      allow(BibleGateway).to receive(:new).with(:NNV).and_return(gateway)
    end

    it "matches the database text when BibleGateway differs only in curly quotes" do
      bible_gateway_returns("Praise the LORD, all you nations; extol him, all you \u201cpeoples\u201d.")
      expect(verse.web_text).to eq(verse.database_text)
    end

    it "does not match when BibleGateway has different words" do
      bible_gateway_returns("This is incorrect")
      expect(verse.web_text).not_to eq(verse.database_text)
    end

    it "is nil when BibleGateway has no content for the reference" do
      bible_gateway_returns(nil)
      expect(verse.web_text).to be_nil
    end
  end

end
