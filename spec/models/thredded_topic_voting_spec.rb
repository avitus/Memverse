require 'rails_helper'

RSpec.describe "Thredded Topic Voting", type: :model do
  let(:user) { FactoryBot.create(:user) }
  let(:another_user) { FactoryBot.create(:user) }
  let(:messageboard) { Thredded::Messageboard.create!(name: "Test Board", slug: "test") }
  let(:topic) { create_topic_with_post(messageboard: messageboard, user: user) }
  
  def create_topic_with_post(messageboard:, user:, title: "Test Topic")
    topic = nil
    Thredded::Topic.transaction do
      topic = Thredded::Topic.create!(
        messageboard: messageboard,
        user: user,
        title: title,
        sticky: false,
        locked: false
      )
      
      Thredded::Post.create!(
        postable: topic,
        user: user,
        content: "Initial post content",
        messageboard: messageboard
      )
    end
    topic.reload
  end
  
  describe "voting methods" do
    it "responds to acts_as_votable methods" do
      expect(topic).to respond_to(:vote_score)
      expect(topic).to respond_to(:voted_by?)
      expect(topic).to respond_to(:vote_direction_by)
      expect(topic).to respond_to(:get_upvotes)
      expect(topic).to respond_to(:get_downvotes)
    end
  end
  
  describe "#vote_score" do
    it "returns 0 for a topic with no votes" do
      expect(topic.vote_score).to eq(0)
    end
    
    it "returns positive score for upvotes" do
      user.likes topic
      another_user.likes topic
      expect(topic.vote_score).to eq(2)
    end
    
    it "returns negative score for downvotes" do
      user.dislikes topic
      another_user.dislikes topic
      expect(topic.vote_score).to eq(-2)
    end
    
    it "calculates net score correctly" do
      user.likes topic
      another_user.dislikes topic
      expect(topic.vote_score).to eq(0)
    end
  end
  
  describe "#voted_by?" do
    it "returns false when user hasn't voted" do
      expect(topic.voted_by?(user)).to be_falsey
    end
    
    it "returns true when user has upvoted" do
      user.likes topic
      expect(topic.voted_by?(user)).to be_truthy
    end
    
    it "returns true when user has downvoted" do
      user.dislikes topic
      expect(topic.voted_by?(user)).to be_truthy
    end
    
    it "returns false for nil user" do
      expect(topic.voted_by?(nil)).to be_falsey
    end
  end
  
  describe "#vote_direction_by" do
    it "returns nil when user hasn't voted" do
      expect(topic.vote_direction_by(user)).to be_nil
    end
    
    it "returns 'up' when user upvoted" do
      user.likes topic
      expect(topic.vote_direction_by(user)).to eq('up')
    end
    
    it "returns 'down' when user downvoted" do
      user.dislikes topic
      expect(topic.vote_direction_by(user)).to eq('down')
    end
    
    it "returns nil for nil user" do
      expect(topic.vote_direction_by(nil)).to be_nil
    end
  end
  
  describe "vote persistence" do
    it "persists votes across reloads" do
      user.likes topic
      topic.reload
      expect(topic.vote_score).to eq(1)
      expect(topic.voted_by?(user)).to be_truthy
    end
    
    it "allows changing vote direction" do
      user.likes topic
      expect(topic.vote_direction_by(user)).to eq('up')
      
      user.dislikes topic
      expect(topic.vote_direction_by(user)).to eq('down')
      expect(topic.vote_score).to eq(-1)
    end
    
    it "allows removing votes" do
      user.likes topic
      expect(topic.voted_by?(user)).to be_truthy
      
      user.unvote_for topic
      expect(topic.voted_by?(user)).to be_falsey
      expect(topic.vote_score).to eq(0)
    end
  end
  
  describe "user voting behavior" do
    it "allows only one vote per user per topic" do
      user.likes topic
      user.likes topic # Second vote shouldn't change anything
      
      expect(topic.get_upvotes.size).to eq(1)
      expect(topic.vote_score).to eq(1)
    end
    
    it "allows different users to vote independently" do
      user.likes topic
      another_user.likes topic
      
      expect(topic.get_upvotes.size).to eq(2)
      expect(topic.vote_score).to eq(2)
    end
  end
end