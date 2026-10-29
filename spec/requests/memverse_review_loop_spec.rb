# frozen_string_literal: true

require 'rails_helper'

# The daily review page (/test_verse_quick) drives two JSON endpoints from
# app/assets/javascripts/memverse.js and the page's inline script:
#   GET /mark_test_quick?mv=&q=   scores the verse the user just typed
#   GET /test_next_verse?mv=      asks which verse to stage next
RSpec.describe 'Memory verse review loop', type: :request do
  let(:user)   { FactoryBot.create(:user, time_allocation: 60) }
  let(:verse1) { FactoryBot.create(:verse, book: 'Psalms', chapter: 117, versenum: 1) }
  let(:verse2) { FactoryBot.create(:verse, book: 'Psalms', chapter: 117, versenum: 2) }
  let!(:mv1)   { FactoryBot.create(:memverse, user: user, verse: verse1) }
  let!(:mv2)   { FactoryBot.create(:memverse, user: user, verse: verse2) }

  before { sign_in user }

  def body
    JSON.parse(response.body)
  end

  describe 'GET /test_verse_quick' do
    it 'renders the first due verse of the signed-in user' do
      get test_verse_quick_path

      expect(response).to have_http_status(:ok)
      expect(assigns(:mv)).to eq(mv1)
      expect(assigns(:mv).user).to eq(user)
    end

    it 'sends the user to their progress page when nothing is due' do
      user.memverses.update_all(next_test: Date.tomorrow) # skipcq: RB-RL1053 (push every verse out of today's queue)

      get test_verse_quick_path

      expect(response).to redirect_to(progress_path)
    end
  end

  describe 'GET /mark_test_quick' do
    it 'advances the schedule for a perfect recall and replies with an empty message' do
      get mark_test_quick_path, params: { mv: mv1.id, q: 5 }

      expect(response).to have_http_status(:ok)
      expect(body).to eq('msg' => nil)

      mv1.reload
      expect(mv1.rep_n).to eq(2)
      expect(mv1.test_interval).to eq(4)
      expect(mv1.next_test).to eq(Date.today + 4) # skipcq: RB-RL1014 (Memverse#supermemo uses Date.today)
    end

    it 'resets the interval after a failed recall' do
      mv1.update!(test_interval: 8, rep_n: 3)

      get mark_test_quick_path, params: { mv: mv1.id, q: 1 }

      mv1.reload
      expect(mv1.test_interval).to eq(1)
      expect(mv1.rep_n).to eq(1)
      expect(mv1.next_test).to eq(Date.tomorrow)
    end

    it 'congratulates the user when the verse crosses into Memorized' do
      mv1.update!(test_interval: 16, rep_n: 3)

      get mark_test_quick_path, params: { mv: mv1.id, q: 5 }

      expect(body['msg']).to start_with("Congratulations. You have memorized #{verse1.ref}.")
      expect(mv1.reload.status).to eq('Memorized')
    end

    it "refuses to score another user's verse" do
      other_mv = FactoryBot.create(:memverse, user: FactoryBot.create(:user))

      expect { get mark_test_quick_path, params: { mv: other_mv.id, q: 5 } }
        .not_to(change { other_mv.reload.attributes })

      expect(response).to have_http_status(:ok)
      expect(body['msg']).to match(/belongs to another user/)
    end
  end

  describe 'GET /test_next_verse' do
    it 'stages the following verse of the passage' do
      get test_next_verse_path, params: { mv: mv1.id }

      expect(response).to have_http_status(:ok)
      expect(body['finished']).to be(false)
      expect(body['mv']['id']).to eq(mv2.id)
      expect(body['prior_mv']['id']).to eq(mv1.id)
    end

    it 'reports the session finished once nothing else is due' do
      get mark_test_quick_path, params: { mv: mv1.id, q: 5 }
      get mark_test_quick_path, params: { mv: mv2.id, q: 5 }

      get test_next_verse_path, params: { mv: mv2.id }

      expect(body).to eq('finished' => true)
    end
  end
end
