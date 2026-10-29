require 'spec_helper'

describe Devotion do
  
  describe "validations" do
    it "is valid with all attributes" do
      devotion = Devotion.new(
        name: "Spurgeon Morning",
        month: 1,
        day: 15,
        thought: "This is a daily devotion thought",
        ref: "John 3:16"
      )
      expect(devotion).to be_valid
    end

    it "can be created and saved to database" do
      devotion = Devotion.create!(
        name: "Spurgeon Morning",
        month: 6,
        day: 20,
        thought: "Trust in the Lord with all your heart",
        ref: "Proverbs 3:5"
      )
      expect(devotion).to be_persisted
      expect(devotion.name).to eq("Spurgeon Morning")
    end
  end

  describe "data storage" do
  end

  describe ".daily_refresh" do
    let(:mock_rss_post) do
      double("RSS Post", 
        description: '<p>This is a devotional thought.</p><a href="#">John 3:16</a><p>More content here.</p>'
      )
    end

    let(:empty_rss_post) do
      double("RSS Post", description: nil)
    end

    before do
      # Clean up any existing devotions for today
      Devotion.where(name: "Spurgeon Morning", month: Date.today.month, day: Date.today.day).destroy_all
    end

    context "when RSS feed returns valid content" do
      before do
        allow(RssReader).to receive(:posts_for).and_return([mock_rss_post])
      end

      it "creates a new devotion record" do
        expect {
          Devotion.daily_refresh
        }.to change { Devotion.count }.by(1)
      end

      it "sets the correct name" do
        Devotion.daily_refresh
        devotion = Devotion.where(name: "Spurgeon Morning", month: Date.today.month, day: Date.today.day).first
        expect(devotion.name).to eq("Spurgeon Morning")
      end

      it "sets the correct month and day" do
        Devotion.daily_refresh
        devotion = Devotion.where(name: "Spurgeon Morning", month: Date.today.month, day: Date.today.day).first
        expect(devotion.month).to eq(Date.today.month)
        expect(devotion.day).to eq(Date.today.day)
      end

      it "stores the thought content" do
        Devotion.daily_refresh
        devotion = Devotion.where(name: "Spurgeon Morning", month: Date.today.month, day: Date.today.day).first
        expect(devotion.thought).to eq(mock_rss_post.description)
      end

      it "extracts and capitalizes the reference" do
        Devotion.daily_refresh
        devotion = Devotion.where(name: "Spurgeon Morning", month: Date.today.month, day: Date.today.day).first
        expect(devotion.ref).to eq("John 3:16")
      end
    end

    context "when RSS feed returns empty content" do
      before do
        allow(RssReader).to receive(:posts_for).and_return([empty_rss_post])
      end

      it "does not create a devotion record when description is nil" do
        expect {
          Devotion.daily_refresh
        }.not_to change { Devotion.count }
      end
    end

    context "when RSS feed returns no posts" do
      before do
        allow(RssReader).to receive(:posts_for).and_return([])
      end

      it "does not create a devotion record" do
        expect {
          Devotion.daily_refresh
        }.not_to change { Devotion.count }
      end
    end

    context "when RSS feed returns nil" do
      before do
        allow(RssReader).to receive(:posts_for).and_return(nil)
      end

      it "does not create a devotion record" do
        expect {
          Devotion.daily_refresh
        }.not_to change { Devotion.count }
      end
    end

    context "when devotion already exists for today" do
      before do
        Devotion.create!(
          name: "Spurgeon Morning",
          month: Date.today.month,
          day: Date.today.day,
          thought: "Existing devotion",
          ref: "Existing ref"
        )
        allow(RssReader).to receive(:posts_for).and_return([mock_rss_post])
      end

      it "does not create a duplicate devotion" do
        expect {
          Devotion.daily_refresh
        }.not_to change { Devotion.count }
      end

      it "does not overwrite existing devotion" do
        original_thought = Devotion.where(name: "Spurgeon Morning", month: Date.today.month, day: Date.today.day).first.thought
        Devotion.daily_refresh
        devotion = Devotion.where(name: "Spurgeon Morning", month: Date.today.month, day: Date.today.day).first
        expect(devotion.thought).to eq(original_thought)
      end
    end

    context "error handling" do
      context "when RssReader raises an exception" do
        before do
          allow(RssReader).to receive(:posts_for).and_raise(StandardError.new("Network error"))
        end

        it "handles the exception gracefully" do
          expect {
            Devotion.daily_refresh
          }.not_to raise_error
        end

        it "does not create a devotion record" do
          expect {
            begin
              Devotion.daily_refresh
            rescue StandardError
              # Swallow the error for this test
            end
          }.not_to change { Devotion.count }
        end
      end

      context "when HTML parsing fails" do
        let(:malformed_rss_post) do
          double("RSS Post", description: "No anchor tag here")
        end

        before do
          allow(RssReader).to receive(:posts_for).and_return([malformed_rss_post])
        end

        it "handles malformed HTML gracefully" do
          expect {
            Devotion.daily_refresh
          }.not_to raise_error
        end
      end
    end
  end

  describe "content security" do
  end

  describe "date-based retrieval" do
    before do
      @jan_devotion = Devotion.create!(
        name: "Spurgeon Morning",
        month: 1,
        day: 15,
        thought: "January devotion",
        ref: "Psalm 1:1"
      )
      
      @june_devotion = Devotion.create!(
        name: "Spurgeon Morning", 
        month: 6,
        day: 15,
        thought: "June devotion",
        ref: "Psalm 6:1"
      )
    end

  end
end