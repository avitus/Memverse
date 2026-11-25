require 'rails_helper'

RSpec.describe 'Passage ratings', type: :request do
  include ActiveSupport::Testing::TimeHelpers
  let(:user) { FactoryBot.create(:user) }
  let(:verse) { FactoryBot.create(:memverse, user: user) }
  let(:initial) { { day: Date.today.iso8601, attempt: verse.attempts } }

  before { sign_in user }

  def rate(quality, previous = nil)
    patch passage_verse_rating_path(verse), params: initial.merge(quality: quality, previous: previous)
  end

  it 'persists and corrects the original attempt, including after a retry or reload' do
    verse.update!(rep_n: 3, test_interval: 8)
    attempts = verse.attempts
    rate(1)
    expect(response).to have_http_status(:ok)
    expect(verse.reload.rep_n).to eq(1)
    rate(1)
    rate(5, 1)
    expect(response).to have_http_status(:ok)
    expect(verse.reload.attempts).to eq(attempts + 1)
    expect(verse.rep_n).to eq(4)
    expect(verse.test_interval).to be > 8
    get passage_memverses_path(verse.passage, format: :json), params: { passage_review: 1 }
    expect(response.parsed_body.first['rating']).to include('attempt' => attempts, 'quality' => 5)
    rate(3, 1)
    expect(response).to have_http_status(:conflict)
    expect(response.parsed_body['rating']['quality']).to eq(5)
  end

  it 'rejects out-of-range scores and attempts superseded by another review' do
    initial
    rate(7)
    expect(response).to have_http_status(:unprocessable_entity)
    verse.supermemo(3)
    rate(4)
    expect(response).to have_http_status(:conflict)
  end

  it 'expires the editable score at the next review day' do
    rate(4)
    travel_to(1.day.from_now) do
      rate(2, 4)
      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body['rating']['quality']).to be_nil
      expect(verse.reload.attempts).to eq(initial[:attempt] + 1)
    end
  end

  it 'limits edits to verses belonging to the signed-in reader' do
    other = FactoryBot.create(:memverse)
    patch passage_verse_rating_path(other), params: { quality: 4 }
    expect(response).to have_http_status(:not_found)
  end
end
