require 'spec_helper'

describe Api::V1::VersesController do

  # let!(:application) { Doorkeeper::Application.create!(:name => "MyApp", :redirect_uri => "https://app.com") } # OAuth application
  # let!(:user)        { FactoryBot.create(:user) }
  # let!(:token)       { Doorkeeper::AccessToken.create! :application_id => application.id, :resource_owner_id => user.id }
  let!(:verse)       { FactoryBot.create(:verse)}

  describe 'GET #show' do

    context 'authenticated with valid token' do

      before do
        allow(controller).to receive(:doorkeeper_token) {token}
      end

      let(:token) { double :acceptable? => true }

      it 'responds with 200' do
        get :show, params: {id: verse.id, version: 1}, format: :json
        expect(response.status).to eq(200)
      end

      it 'returns a verse in JSON format' do
        get :show, params: {id: verse.id, version: 1}, format: :json
        expect(json["text"]).to eq(JSON.parse(verse.to_json)["text"])
      end

    end


    context 'no valid access token' do

      it 'responds with 401 when unauthorized' do
        get :show, params: {id: verse.id, version: 1}, format: :json
        expect(response.status).to eq(401)
      end
    
    end

  end

  describe 'GET #chapter' do

    before do
      allow(controller).to receive(:doorkeeper_token) {token}
    end

    let(:token) { double :acceptable? => true, :resource_owner_id => user.id }
    let(:user)  { FactoryBot.create(:user, translation: 'NIV') }

    let!(:chapter_verses) do
      (1..2).map { |n| FactoryBot.create(:verse, book: 'Psalms', chapter: 117, versenum: n, translation: 'NIV') }
    end

    it 'returns the verses of the chapter in the requested translation' do
      get :chapter, params: {bk: 'Psalms', ch: 117, tl: 'NIV', version: 1}, format: :json

      expect(response.status).to eq(200)
      expect(json.map { |v| v['id'] }).to match_array(chapter_verses.map(&:id))
      expect(json.first.keys).to include('id', 'book', 'chapter', 'versenum', 'translation', 'ref', 'text')
    end

    it "falls back to the token owner's translation" do
      FactoryBot.create(:verse, book: 'Psalms', chapter: 117, versenum: 1, translation: 'ESV')

      get :chapter, params: {bk: 'Psalms', ch: 117, version: 1}, format: :json

      expect(json.map { |v| v['translation'] }.uniq).to eq(['NIV'])
    end

    it 'returns an empty page for a chapter that is not in the database' do
      get :chapter, params: {bk: 'Psalms', ch: 150, tl: 'NIV', version: 1}, format: :json

      expect(response.status).to eq(200)
      expect(json).to eq([])
      expect(JSON.parse(response.body)['count']).to eq(0)
    end
  end

  describe 'GET #search' do

    before do
      allow(controller).to receive(:doorkeeper_token) {token}
    end

    let(:token) { double :acceptable? => true }

    # Verse.search is Thinking Sphinx, which does not run in the test suite
    it 'returns the verses matching the search text' do
      allow(Verse).to receive(:search).with('nations').and_return([verse])

      get :search, params: {searchParams: 'nations', version: 1}, format: :json

      expect(response.status).to eq(200)
      expect(json.map { |v| v['id'] }).to eq([verse.id])
      expect(json.first['text']).to eq(verse.text)
    end

    it 'returns an empty list when no search text is given' do
      expect(Verse).not_to receive(:search)

      get :search, params: {version: 1}, format: :json

      expect(response.status).to eq(200)
      expect(json).to eq([])
    end
  end

  describe 'GET #lookup' do

    context 'authenticated with valid token' do

      before do
        allow(controller).to receive(:doorkeeper_token) {token}
      end

      let(:token) { double :acceptable? => true }

      it 'lookups a verse' do
        # Create the specific verse that the test is looking for
        FactoryBot.create(:verse, book: 'Psalms', chapter: 117, versenum: 1, translation: 'NIV')
        
        get :lookup, params: {tl: 'NIV', bk: 'Psalms', ch: 117, vs: 1, version: 1}, format: :json
        expect(response.status).to eq(200)
        expect(json["text"]).to eq('Praise the LORD, all you nations; extol him, all you peoples.')
      end

    end

  end

end
