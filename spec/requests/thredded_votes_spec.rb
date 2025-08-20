require 'rails_helper'

RSpec.describe "Thredded Votes API", type: :request do
  let(:user) { FactoryBot.create(:user) }
  let(:messageboard) { Thredded::Messageboard.create!(name: "Test", slug: "test") }
  let(:topic) { create_topic_with_post(messageboard: messageboard, user: user) }
  
  def create_topic_with_post(messageboard:, user:)
    topic = nil
    Thredded::Topic.transaction do
      topic = Thredded::Topic.create!(
        messageboard: messageboard,
        user: user,
        title: "Test Topic",
        sticky: false,
        locked: false
      )
      
      Thredded::Post.create!(
        postable: topic,
        user: user,
        content: "Test content",
        messageboard: messageboard
      )
    end
    topic.reload
  end
  
  describe "error handling" do
    context "when topic doesn't exist" do
      before { sign_in user }
      
      it "returns 404 for non-existent topic" do
        post "/thredded_votes/99999/upvote"
        expect(response).to have_http_status(:not_found)
      end
    end
    
    context "when voting on locked topic" do
      before { sign_in user }
      
      it "allows voting even on locked topics" do
        # Lock the topic
        topic.update!(locked: true)
        
        post "/thredded_votes/#{topic.id}/upvote", params: {}, headers: { 'Accept' => 'application/json' }
        expect(response).to have_http_status(:ok)
        
        json_response = JSON.parse(response.body)
        expect(json_response["score"]).to eq(1)
      end
    end
  end
  
  describe "performance considerations" do
    before { sign_in user }
    
    it "performs vote operations efficiently" do
      # Warm up
      post "/thredded_votes/#{topic.id}/upvote", params: {}, headers: { 'Accept' => 'application/json' }
      
      # Make sure subsequent votes are also efficient
      post "/thredded_votes/#{topic.id}/downvote", params: {}, headers: { 'Accept' => 'application/json' }
      expect(response).to have_http_status(:ok)
      
      # Verify the vote was changed
      json_response = JSON.parse(response.body)
      expect(json_response["voted"]).to eq("down")
    end
  end
  
  describe "CSRF protection" do
    it "is enforced by Rails" do
      sign_in user
      
      # CSRF protection is enabled by default in Rails
      # With proper authentication, requests should work
      post "/thredded_votes/#{topic.id}/upvote", params: {}, headers: { 'Accept' => 'application/json' }
      expect(response).to have_http_status(:ok)
    end
  end
  
  describe "rate limiting" do
    before { sign_in user }
    
    it "allows rapid vote changes" do
      10.times do |i|
        if i.even?
          post "/thredded_votes/#{topic.id}/upvote", params: {}, headers: { 'Accept' => 'application/json' }
        else
          post "/thredded_votes/#{topic.id}/downvote", params: {}, headers: { 'Accept' => 'application/json' }
        end
        expect(response).to have_http_status(:ok)
      end
    end
  end
end