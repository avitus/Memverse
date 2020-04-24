describe API::V1::Verse do

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
        response.status.should eq(200)
      end

      it 'returns a verse in JSON format' do
        get :show, params: {id: verse.id, version: 1}, format: :json
        json["text"].should == JSON.parse(verse.to_json)["text"]
      end

    end


    context 'no valid access token' do

      it 'responds with 401 when unauthorized' do
        get :show, params: {id: verse.id, version: 1}, format: :json
        response.status.should eq(401)
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
        get :lookup, params: {tl: 'NIV', bk: 'Galatians', ch: 5, vs: 22, version: 1}, format: :json
        response.status.should eq(200)
        json["text"].should == 'But the fruit of the Spirit is love, joy, peace, patience, kindness, goodness, faithfulness,'
      end

    end

  end

end
