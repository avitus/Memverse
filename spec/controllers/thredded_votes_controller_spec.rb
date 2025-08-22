require 'rails_helper'

RSpec.describe ThreddedVotesController, type: :controller do
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
  
  describe "authentication" do
    it "requires user to be signed in for upvote" do
      post :upvote, params: { id: topic.id }
      expect(response).to redirect_to(new_user_session_path)
    end
    
    it "requires user to be signed in for downvote" do
      post :downvote, params: { id: topic.id }
      expect(response).to redirect_to(new_user_session_path)
    end
    
    it "requires user to be signed in for unvote" do
      delete :unvote, params: { id: topic.id }
      expect(response).to redirect_to(new_user_session_path)
    end
  end
  
  describe "POST #upvote" do
    before { sign_in user }
    
    context "with HTML format" do
      it "upvotes the topic and redirects back" do
        request.env["HTTP_REFERER"] = "/forum/test/#{topic.slug}"
        
        expect {
          post :upvote, params: { id: topic.id }
        }.to change { topic.reload.vote_score }.from(0).to(1)
        
        expect(response).to redirect_to("/forum/test/#{topic.slug}")
      end
      
      it "redirects to topic path when no referrer" do
        post :upvote, params: { id: topic.id }
        expect(response).to redirect_to("/forum/#{messageboard.slug}/#{topic.slug}")
      end
    end
    
    context "with JSON format" do
      it "returns vote score and direction" do
        post :upvote, params: { id: topic.id }, format: :json
        
        json_response = JSON.parse(response.body)
        expect(json_response["score"]).to eq(1)
        expect(json_response["voted"]).to eq("up")
        expect(response).to have_http_status(:ok)
      end
      
      it "changes existing downvote to upvote" do
        user.dislikes topic
        
        post :upvote, params: { id: topic.id }, format: :json
        
        json_response = JSON.parse(response.body)
        expect(json_response["score"]).to eq(1)
        expect(json_response["voted"]).to eq("up")
      end
    end
  end
  
  describe "POST #downvote" do
    before { sign_in user }
    
    context "with HTML format" do
      it "downvotes the topic and redirects back" do
        request.env["HTTP_REFERER"] = "/forum/test/#{topic.slug}"
        
        expect {
          post :downvote, params: { id: topic.id }
        }.to change { topic.reload.vote_score }.from(0).to(-1)
        
        expect(response).to redirect_to("/forum/test/#{topic.slug}")
      end
    end
    
    context "with JSON format" do
      it "returns vote score and direction" do
        post :downvote, params: { id: topic.id }, format: :json
        
        json_response = JSON.parse(response.body)
        expect(json_response["score"]).to eq(-1)
        expect(json_response["voted"]).to eq("down")
        expect(response).to have_http_status(:ok)
      end
      
      it "changes existing upvote to downvote" do
        user.likes topic
        
        post :downvote, params: { id: topic.id }, format: :json
        
        json_response = JSON.parse(response.body)
        expect(json_response["score"]).to eq(-1)
        expect(json_response["voted"]).to eq("down")
      end
    end
  end
  
  describe "DELETE #unvote" do
    before { sign_in user }
    
    context "with existing upvote" do
      before { user.likes topic }
      
      it "removes the vote" do
        expect {
          delete :unvote, params: { id: topic.id }, format: :json
        }.to change { topic.reload.vote_score }.from(1).to(0)
        
        json_response = JSON.parse(response.body)
        expect(json_response["score"]).to eq(0)
        expect(json_response["voted"]).to be_nil
      end
    end
    
    context "with existing downvote" do
      before { user.dislikes topic }
      
      it "removes the vote" do
        expect {
          delete :unvote, params: { id: topic.id }, format: :json
        }.to change { topic.reload.vote_score }.from(-1).to(0)
      end
    end
    
    context "with no existing vote" do
      it "returns current score without error" do
        delete :unvote, params: { id: topic.id }, format: :json
        
        json_response = JSON.parse(response.body)
        expect(json_response["score"]).to eq(0)
        expect(json_response["voted"]).to be_nil
        expect(response).to have_http_status(:ok)
      end
    end
    
    context "bug fix: user votes then unvotes on topic with 0 score" do
      it "should return to 0 score, not -1" do
        # Start with topic at 0 votes
        expect(topic.vote_score).to eq(0)
        expect(topic.get_upvotes.size).to eq(0)
        expect(topic.get_downvotes.size).to eq(0)
        
        # User upvotes
        post :upvote, params: { id: topic.id }, format: :json
        topic.reload
        expect(topic.vote_score).to eq(1)
        expect(topic.get_upvotes.size).to eq(1)
        expect(topic.get_downvotes.size).to eq(0)
        
        # User unvotes - should go back to 0, not -1
        delete :unvote, params: { id: topic.id }, format: :json
        topic.reload
        expect(topic.vote_score).to eq(0)
        expect(topic.get_upvotes.size).to eq(0)
        expect(topic.get_downvotes.size).to eq(0)
        
        json_response = JSON.parse(response.body)
        expect(json_response["score"]).to eq(0)
      end
      
      it "should correctly handle multiple users voting scenario" do
        # Simulate the exact bug scenario
        # Topic starts at 0
        expect(topic.vote_score).to eq(0)
        
        # First user upvotes
        sign_in user
        post :upvote, params: { id: topic.id }, format: :json
        expect(topic.reload.vote_score).to eq(1)
        
        # First user removes vote
        delete :unvote, params: { id: topic.id }, format: :json
        topic.reload
        
        # Check that score is 0, not -1
        expect(topic.vote_score).to eq(0)
        expect(topic.get_upvotes.size).to eq(0)
        expect(topic.get_downvotes.size).to eq(0)
      end
    end
  end
  
  describe "authorization" do
    before { sign_in user }
    
    context "with non-existent topic" do
      it "returns 404 for non-existent topic" do
        post :upvote, params: { id: 99999 }
        expect(response).to have_http_status(:not_found)
      end
    end
    
    context "with topic from different messageboard" do
      let(:other_board) { Thredded::Messageboard.create!(name: "Other Board", slug: "other") }
      let(:other_topic) { create_topic_with_post(messageboard: other_board, user: user) }
      
      it "allows voting on topics from any messageboard" do
        post :upvote, params: { id: other_topic.id }, format: :json
        expect(response).to have_http_status(:ok)
        expect(other_topic.reload.vote_score).to eq(1)
      end
    end
  end
  
  describe "concurrent voting" do
    before { sign_in user }
    
    it "handles multiple users voting simultaneously" do
      # User 1 votes
      post :upvote, params: { id: topic.id }, format: :json
      
      # User 2 votes
      sign_in another_user
      post :upvote, params: { id: topic.id }, format: :json
      
      json_response = JSON.parse(response.body)
      expect(json_response["score"]).to eq(2)
      expect(topic.reload.vote_score).to eq(2)
    end
  end
end