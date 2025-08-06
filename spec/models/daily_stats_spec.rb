require 'spec_helper'

describe DailyStats do
  
  describe "validations" do
    it "is valid with required attributes" do
      daily_stats = DailyStats.new(entry_date: Date.today)
      expect(daily_stats).to be_valid
    end

    it "requires an entry_date" do
      daily_stats = DailyStats.new
      expect(daily_stats).not_to be_valid
      expect(daily_stats.errors[:entry_date]).to include("can't be blank")
    end

    it "accepts all attributes" do
      daily_stats = DailyStats.new(
        entry_date: Date.today,
        segment: "Global",
        users: 100,
        users_active_in_month: 50,
        verses: 1000,
        memverses: 500,
        memverses_memorized: 200,
        memverses_learning: 300,
        memverses_memorized_not_overdue: 150,
        memverses_learning_active_in_month: 250
      )
      expect(daily_stats).to be_valid
    end
  end

  describe "scopes" do
    let!(:global_stats) { DailyStats.create!(entry_date: Date.today, segment: "Global") }
    let!(:american_stats) { DailyStats.create!(entry_date: Date.today, segment: "United States") }
    let!(:other_stats) { DailyStats.create!(entry_date: Date.today, segment: "Canada") }

    describe ".global" do
      it "returns only global segment records" do
        expect(DailyStats.global).to include(global_stats)
        expect(DailyStats.global).not_to include(american_stats)
        expect(DailyStats.global).not_to include(other_stats)
      end
    end

    describe ".american" do
      it "returns only United States segment records" do
        expect(DailyStats.american).to include(american_stats)
        expect(DailyStats.american).not_to include(global_stats)
        expect(DailyStats.american).not_to include(other_stats)
      end
    end
  end

  describe ".update" do
    before do
      # Clean up any existing records for today
      DailyStats.where(entry_date: Date.today).destroy_all
      
      # Create test data
      @user1 = FactoryBot.create(:user)
      @user2 = FactoryBot.create(:user, american_state: FactoryBot.create(:american_state, :name => "California"))
      @verse1 = FactoryBot.create(:verse)
      @verse2 = FactoryBot.create(:verse, book: "Exodus", chapter: 1, versenum: 1)
      @memverse1 = FactoryBot.create(:memverse, user: @user1, verse: @verse1, status: "Memorized")
      @memverse2 = FactoryBot.create(:memverse, user: @user2, verse: @verse2, status: "Learning")
    end

    context "when no record exists for today" do
      it "creates a new global daily stats record" do
        expect {
          DailyStats.update
        }.to change { DailyStats.global.count }.by(1)
      end

      it "creates a new US daily stats record" do
        expect {
          DailyStats.update
        }.to change { DailyStats.american.count }.by(1)
      end

      it "sets the entry_date to today" do
        DailyStats.update
        global_record = DailyStats.global.where(entry_date: Date.today).first
        us_record = DailyStats.american.where(entry_date: Date.today).first
        
        expect(global_record.entry_date).to eq(Date.today)
        expect(us_record.entry_date).to eq(Date.today)
      end

      it "captures user counts" do
        DailyStats.update
        global_record = DailyStats.global.where(entry_date: Date.today).first
        
        expect(global_record.users).to eq(User.count)
        expect(global_record.users_active_in_month).to eq(User.active.count)
      end

      it "captures verse counts" do
        DailyStats.update
        global_record = DailyStats.global.where(entry_date: Date.today).first
        
        expect(global_record.verses).to eq(Verse.count)
      end

      it "captures memverse counts" do
        DailyStats.update
        global_record = DailyStats.global.where(entry_date: Date.today).first
        
        expect(global_record.memverses).to eq(Memverse.count)
        expect(global_record.memverses_memorized).to eq(Memverse.memorized.count)
        expect(global_record.memverses_learning).to eq(Memverse.learning.count)
      end

      it "sets the US segment correctly" do
        DailyStats.update
        us_record = DailyStats.american.where(entry_date: Date.today).first
        
        expect(us_record.segment).to eq("United States")
      end

      it "captures US-specific counts" do
        DailyStats.update
        us_record = DailyStats.american.where(entry_date: Date.today).first
        
        expect(us_record.users).to eq(User.american.count)
        expect(us_record.users_active_in_month).to eq(User.american.active.count)
        expect(us_record.memverses).to eq(Memverse.american.count)
        expect(us_record.memverses_memorized).to eq(Memverse.american.memorized.count)
        expect(us_record.memverses_learning).to eq(Memverse.american.learning.count)
      end
    end

    context "when a record already exists for today" do
      before do
        DailyStats.create!(entry_date: Date.today, segment: "Global")
        DailyStats.create!(entry_date: Date.today, segment: "United States")
      end

      it "does not create a new global record" do
        expect {
          DailyStats.update
        }.not_to change { DailyStats.global.count }
      end

      it "does not create a new US record" do
        expect {
          DailyStats.update
        }.not_to change { DailyStats.american.count }
      end
    end
  end

  describe "data integrity" do
    it "allows multiple records for different dates" do
      stats1 = DailyStats.create!(entry_date: Date.today)
      stats2 = DailyStats.create!(entry_date: Date.yesterday)
      
      expect(stats1).to be_valid
      expect(stats2).to be_valid
    end

    it "allows multiple records for different segments on the same date" do
      global_stats = DailyStats.create!(entry_date: Date.today, segment: "Global")
      us_stats = DailyStats.create!(entry_date: Date.today, segment: "United States")
      
      expect(global_stats).to be_valid
      expect(us_stats).to be_valid
    end

    it "stores numeric values correctly" do
      stats = DailyStats.create!(
        entry_date: Date.today,
        users: 150,
        users_active_in_month: 75,
        verses: 2000,
        memverses: 1000,
        memverses_memorized: 400,
        memverses_learning: 600
      )
      
      stats.reload
      expect(stats.users).to eq(150)
      expect(stats.users_active_in_month).to eq(75)
      expect(stats.verses).to eq(2000)
      expect(stats.memverses).to eq(1000)
      expect(stats.memverses_memorized).to eq(400)
      expect(stats.memverses_learning).to eq(600)
    end
  end
end