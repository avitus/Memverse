# frozen_string_literal: true

require 'rails_helper'

# Adding a whole chapter (POST /add_chapter from the add-verse page) and
# deleting verses from the manage page (POST /delete_memverses).
RSpec.describe 'Chapter add and verse deletion', type: :request do
  let(:user) { FactoryBot.create(:user, time_allocation: 60) }

  # 3 John 1 has 14 verses; only the first three exist in the test DB, so the
  # chapter add is limited to those rows.
  let!(:verses) do
    (1..3).map { |n| FactoryBot.create(:verse, book: '3 John', book_index: 64, chapter: 1, versenum: n, translation: 'NIV') }
  end

  before { sign_in user }

  def add_chapter
    post add_chapter_path, params: { bk: '3 John', ch: 1, tl: 'NIV' }
  end

  def memverses_in_order
    user.memverses.canonical_sort.to_a
  end

  describe 'POST /add_chapter' do
    it 'creates one memory verse per verse in the chapter and confirms as JSON' do
      expect { add_chapter }.to change { user.memverses.count }.from(0).to(3)

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq('msg' => 'Added Chapter')
      expect(user.memverses.map(&:verse)).to match_array(verses)
    end

    it 'links the verses into a sequence' do
      add_chapter
      first, middle, last = memverses_in_order

      expect(first.prev_verse).to be_nil
      expect(first.next_verse).to eq(middle.id)
      expect(middle.prev_verse).to eq(first.id)
      expect(middle.next_verse).to eq(last.id)
      expect(last.next_verse).to be_nil
      expect([middle.first_verse, last.first_verse]).to eq([first.id, first.id])
    end

    it 'groups the verses into a single passage covering the chapter' do
      add_chapter

      expect(user.passages.count).to eq(1)
      passage = user.passages.first
      expect(passage).to have_attributes(book: '3 John', chapter: 1, first_verse: 1, last_verse: 3, length: 3, reference: '3 John 1:1-3')
      expect(user.memverses.pluck(:passage_id).uniq).to eq([passage.id])
    end

    it 'does not duplicate anything when the chapter is added again' do
      add_chapter

      expect { add_chapter }.not_to(change { [user.memverses.count, user.passages.count] })
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST /delete_memverses' do
    before { add_chapter }

    def delete_memverses(ids)
      post '/delete_memverses', params: { mv: ids.map(&:to_s), Delete: 'Delete' }
    end

    it 'removes the selected verses and shrinks the passage' do
      first, middle, last = memverses_in_order

      delete_memverses([last.id])

      expect(response).to redirect_to(manage_verses_path)
      expect(user.memverses.reload).to match_array([first, middle])
      expect(user.passages.first).to have_attributes(first_verse: 1, last_verse: 2, length: 2, reference: '3 John 1:1-2')
      expect(middle.reload.next_verse).to be_nil
    end

    it 'destroys the passage once its last verse is gone' do
      delete_memverses(memverses_in_order.map(&:id))

      expect(user.memverses.count).to eq(0)
      expect(user.passages.count).to eq(0)
    end

    it "leaves another user's verses alone when their ids are submitted" do
      other_mv = FactoryBot.create(:memverse, user: FactoryBot.create(:user))
      own_mv   = memverses_in_order.last

      delete_memverses([own_mv.id, other_mv.id])

      expect(response).to redirect_to(manage_verses_path)
      expect(Memverse.exists?(own_mv.id)).to be(false)
      expect(Memverse.exists?(other_mv.id)).to be(true)
    end

    it 'does nothing without a selection' do
      post '/delete_memverses', params: { Delete: 'Delete' }

      expect(response).to redirect_to(manage_verses_path)
      expect(flash[:notice]).to eq('You did not select any verses.')
      expect(user.memverses.count).to eq(3)
    end
  end
end
