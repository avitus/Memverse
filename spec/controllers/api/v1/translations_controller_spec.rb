describe Api::V1::TranslationsController do

  # These are only used for testing with the controller integrated into app
  # It would be nice to do a full integration test but can't get it to work with scopes

  # let!(:application) { Doorkeeper::Application.create!(:name => "MyApp", :redirect_uri => "https://app.com") } # OAuth application
  # let!(:user)        { FactoryBot.create(:user) }
  # let!(:token)       { Doorkeeper::AccessToken.create! :application_id => application.id, :resource_owner_id => user.id, :scope => 'public' }

  describe 'GET #index' do

    context 'authenticated with valid token' do

      before do
        allow(controller).to receive(:doorkeeper_token) {token}
      end

      let(:token) { double :acceptable? => true }

      it 'responds with 200' do
        get :index, params: {version: 1}, :format => :json
        response.status.should eq(200)
      end

      it 'returns translations as json' do
        get :index, params: {version: 1}, :format => :json
        json.should == JSON.parse(Translation.for_api.to_json)
      end

    end

    context 'no valid access token' do

      it 'responds with 401' do
        get :index, params: {version: 1}, :format => :json
        response.status.should eq(401)
      end

    end

  end

end

