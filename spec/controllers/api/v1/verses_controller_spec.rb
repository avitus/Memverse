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
