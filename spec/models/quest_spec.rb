require 'spec_helper'

describe Quest do
  before(:each) do
    @user = FactoryGirl.create(:user)
  end

  let(:gospel) { FactoryGirl.create(:verse, book: "Matthew", book_index: 40) }
  let(:prophet) { FactoryGirl.create(:verse, book: "Isaiah", book_index: 39) }

  def create_chapter(book, chapter, user, status)
    last = FinalVerse.where(book: book, chapter: chapter).first.last_verse

    for i in 1..last
      vs = FactoryGirl.create(:verse, book: book, book_index: BIBLEBOOKS[:en].values.index(book)+1, chapter: chapter, versenum: i)
      mv = FactoryGirl.create(:memverse, verse: vs, user: user)
      mv.update_attribute(:status, status)
    end

    while true
      # wait until chapter is recognized (verse linking complete)
      book = "Psalm" if book == "Psalms"
      return if user.complete_chapters.include?([status, "#{book} #{chapter}"])
      sleep 1e-1
    end
  end

  describe '.complete?' do
    describe "for verse category goals" do
      it "for 'Learning'" do
        quest = FactoryGirl.create(:quest, objective: 'Gospels', qualifier: 'Learning', quantity: 1)

        FactoryGirl.create(:memverse, user: @user, verse: prophet)
        quest.complete?(@user).should == false

        FactoryGirl.create(:memverse, user: @user, verse: gospel)
        quest.complete?(@user).should == true
      end

      it "for 'Memorized'" do
        quest = FactoryGirl.create(:quest, objective: 'Prophecy', qualifier: 'Memorized', quantity: 1)
        mv = FactoryGirl.create(:memverse, user: @user)
        mv.update_attributes(test_interval: 31, status: "Memorized")

        mv.update_attribute(:verse, gospel)
        quest.complete?(@user).should == false

        mv.update_attribute(:verse, prophet)
        quest.complete?(@user).should == true
      end
    end

    describe "for verse goals" do
      it "for 'Learning'" do

      end

      it "for 'Memorized'" do
      end
    end

    describe "for chapter goals" do
      it "for 'Learning'" do
        quest = FactoryGirl.create(:quest, objective: 'Chapters', qualifier: 'Learning', quantity: 2)

        create_chapter("Psalms", 11, @user, "Learning")
        quest.complete?(@user).should == false

        create_chapter("Psalms", 12, @user, "Learning")
        quest.complete?(@user).should == true
      end

      it "for 'Memorized'" do
        quest = FactoryGirl.create(:quest, objective: 'Chapters', qualifier: 'Memorized', quantity: 2)

        create_chapter("Psalms", 13, @user, "Memorized")
        quest.complete?(@user).should == false

        create_chapter("Psalms", 14, @user, "Memorized")
        quest.complete?(@user).should == true
      end

      it "for memorizing particular chapter" do
        quest = FactoryGirl.create(:quest, objective: 'Chapters', qualifier: 'Psalm 8', quantity: 1)

        create_chapter("Psalms", 23, @user, "Memorized")
        quest.complete?(@user).should == false

        create_chapter("Psalms", 8, @user, "Memorized")
        quest.complete?(@user).should == true
      end
    end

    describe "for book goals" do
      it "should return false -- feature not implemented" do
        quest = FactoryGirl.create(:quest, objective: 'Books', qualifier: 'Learning', quantity: 1)

        create_chapter("Jude", 1, @user, "Learning")
        quest.complete?(@user).should == false
      end
    end

    describe "for accuracy goals" do
      it "should work" do
        quest = FactoryGirl.create(:quest, objective: 'Accuracy', quantity: 70)

        # incomplete without doing anything
        quest.complete?(@user).should == false

        @user.accuracy = 69
        quest.complete?(@user).should == false

        @user.accuracy = 70
        quest.complete?(@user).should == true
      end
    end

    describe "for references goals" do
      it "should work" do
        quest = FactoryGirl.create(:quest, objective: 'References', quantity: 70)

        # incomplete without doing anything
        quest.complete?(@user).should == false

        @user.ref_grade = 69
        quest.complete?(@user).should == false

        @user.ref_grade = 70
        quest.complete?(@user).should == true
      end
    end

    describe "for session goals" do
      it "should work" do
        quest = FactoryGirl.create(:quest, objective: 'Sessions', quantity: 3)

        # incomplete without doing anything
        quest.complete?(@user).should == false

        for i in 1..3
          FactoryGirl.create(:progress_report, user: @user, entry_date: Date.today - i.days)
        end

        quest.complete?(@user).should == true
      end
    end

    describe "for annual session goals" do
      before(:each) do
        @quest = FactoryGirl.create(:quest, objective: 'Annual Sessions', quantity: 5)
      end

      it "should be incomplete without doing anything" do
        @quest.complete?(@user).should == false
      end

      it "should not count sessions from over a year ago" do
        for i in 1..5
          FactoryGirl.create(:progress_report, user: @user, entry_date: Date.today - (12+i).months)
        end

        @quest.complete?(@user).should == false
      end

      it "should count sessions from present year" do
        for i in 1..5
          FactoryGirl.create(:progress_report, user: @user, entry_date: Date.today - i.months)
        end

        @quest.complete?(@user).should == true
      end
    end

    describe "for referral goals" do
      before(:each) do
        @quest = FactoryGirl.create(:quest, objective: 'Referrals', quantity: 5)
      end

      it "should be incomplete without doing anything" do
        @quest.complete?(@user).should == false
      end

      it "should count referrals" do
        for i in 1..5
          FactoryGirl.create(:user, referred_by: @user.id)
        end

        @quest.complete?(@user).should == true
      end
    end

  end

end
