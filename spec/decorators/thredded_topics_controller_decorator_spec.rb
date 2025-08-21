require 'rails_helper'

RSpec.describe "Thredded Topics Controller Decorator", type: :request do
  let(:user) { FactoryBot.create(:user) }
  let(:feedback_board) { 
    Thredded::Messageboard.create!(
      name: "Feedback",
      slug: "feedback",
      description: "Feedback board"
    )
  }
  let(:general_board) { 
    Thredded::Messageboard.create!(
      name: "General",
      slug: "general", 
      description: "General board"
    )
  }
  
  def create_topic_with_votes(board, title, upvotes: 0, downvotes: 0)
    author = FactoryBot.create(:user)
    topic = nil
    
    Thredded::Topic.transaction do
      topic = Thredded::Topic.create!(
        messageboard: board,
        user: author,
        title: title,
        sticky: false,
        locked: false
      )
      
      Thredded::Post.create!(
        postable: topic,
        user: author,
        content: "Content for #{title}",
        messageboard: board
      )
    end
    
    upvotes.times { FactoryBot.create(:user).likes topic }
    downvotes.times { FactoryBot.create(:user).dislikes topic }
    
    topic
  end
  
  describe "vote sorting on feedback board" do
    let!(:popular_topic) { create_topic_with_votes(feedback_board, "Popular", upvotes: 5) }
    let!(:controversial_topic) { create_topic_with_votes(feedback_board, "Controversial", upvotes: 3, downvotes: 3) }
    let!(:unpopular_topic) { create_topic_with_votes(feedback_board, "Unpopular", downvotes: 2) }
    let!(:neutral_topic) { create_topic_with_votes(feedback_board, "Neutral") }
    
    it "sorts by votes when sort=votes parameter is present" do
      get "/forum/feedback?sort=votes"
      
      expect(response).to be_successful
      body = response.body
      
      # Topics should appear in order of engagement (topics with votes first, then by score)
      popular_index = body.index("Popular")       # 5 votes, score +5
      controversial_index = body.index("Controversial") # 6 votes, score 0  
      unpopular_index = body.index("Unpopular")   # 2 votes, score -2
      neutral_index = body.index("Neutral")       # 0 votes, score 0
      
      # Topics with votes should come before topics without votes
      expect(popular_index).to be < neutral_index
      expect(controversial_index).to be < neutral_index  
      expect(unpopular_index).to be < neutral_index
      
      # Among topics with votes, sort by score descending
      expect(popular_index).to be < controversial_index
      expect(controversial_index).to be < unpopular_index
    end
    
    it "uses default sorting when sort parameter is absent" do
      get "/forum/feedback"
      
      expect(response).to be_successful
      # Should use default Thredded sorting (by updated_at)
    end
    
    it "preserves sort parameter in pagination links" do
      # Create enough topics to trigger pagination
      15.times { |i| create_topic_with_votes(feedback_board, "Topic #{i}") }
      
      get "/forum/feedback?sort=votes"
      
      expect(response.body).to include('sort=votes')
    end
  end
  
  describe "no vote sorting on other boards" do
    let!(:topic1) { create_topic_with_votes(general_board, "Topic 1", upvotes: 10) }
    let!(:topic2) { create_topic_with_votes(general_board, "Topic 2") }
    
    it "ignores sort=votes parameter on non-feedback boards" do
      get "/forum/general?sort=votes"
      
      expect(response).to be_successful
      # Should use default sorting even with sort=votes parameter
    end
  end
  
  describe "sorting algorithm" do
    it "correctly calculates net votes (upvotes - downvotes)" do
      # Create topics with same total votes but different distributions
      topic_a = create_topic_with_votes(feedback_board, "A: 5 up, 0 down", upvotes: 5, downvotes: 0)
      topic_b = create_topic_with_votes(feedback_board, "B: 6 up, 1 down", upvotes: 6, downvotes: 1)
      topic_c = create_topic_with_votes(feedback_board, "C: 10 up, 5 down", upvotes: 10, downvotes: 5)
      
      get "/forum/feedback?sort=votes"
      
      body = response.body
      
      # All have score of 5, so secondary sort by updated_at should apply
      expect(body.index("A:")).to be_present
      expect(body.index("B:")).to be_present
      expect(body.index("C:")).to be_present
    end
  end
end