require 'rails_helper'

RSpec.describe ThreddedVotesController, type: :controller do
  let(:user) { FactoryBot.create(:user) }
  let(:messageboard) { Thredded::Messageboard.create!(name: 'Test Board', slug: 'test') }
  let(:topic) { Thredded::Topic.create!(
    messageboard: messageboard,
    user: user,
    title: 'Test Topic'
  )}

  before do
    sign_in user
  end

  describe 'POST #upvote' do
    it 'creates an upvote for the topic' do
      post :upvote, params: { id: topic.id }
      expect(topic.get_upvotes.size).to eq(1)
      expect(topic.vote_score).to eq(1)
    end

    it 'returns JSON with vote data' do
      post :upvote, params: { id: topic.id }, format: :json
      json = JSON.parse(response.body)
      expect(json['score']).to eq(1)
      expect(json['voted']).to eq('up')
    end
  end

  describe 'POST #downvote' do
    it 'creates a downvote for the topic' do
      post :downvote, params: { id: topic.id }
      expect(topic.get_downvotes.size).to eq(1)
      expect(topic.vote_score).to eq(-1)
    end
  end

  describe 'DELETE #unvote' do
    before do
      topic.upvote_by user
    end

    it 'removes the vote' do
      delete :unvote, params: { id: topic.id }
      expect(topic.vote_score).to eq(0)
    end
  end

  context 'when not authenticated' do
    before do
      sign_out user
    end

    it 'redirects to login' do
      post :upvote, params: { id: topic.id }
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end