describe Api::V1::UsersController do

  let(:user) { FactoryBot.create(:user) }

  describe 'POST #create' do 

    it 'creates a new user' do 
      expect {
        post :create, params: {user: {name: 'Test User', email: 'test@memverse.com', password: 'password123' }, version: 1}, format: :json
      }.to change(User, :count).by(1)
      response.status.should eq(200)
    end

    it 'should not allow duplicate emails' do 
      expect {
        post :create, params: {user: {name: 'Duplicate User 1', email: 'duplicate@memverse.com', password: 'password123' }, version: 1}, format: :json
        post :create, params: {user: {name: 'Duplicate User 2', email: 'duplicate@memverse.com', password: 'password123' }, version: 1}, format: :json
      }.to change(User, :count).by(1)
      response.status.should eq(403)  # 403 = this operation is forbidden by server
    end

  end

  describe 'GET #show' do

    context 'authenticated with valid token' do

      before do
        allow(controller).to receive(:doorkeeper_token) {token}
      end

      let(:token) { double :acceptable? => true }

      it 'responds with 200' do
        get :show, params: {id: user.id, version: 1}, format: :json
        response.status.should eq(200)
      end

      #it 'returns user attributes as json' do
      #  get :show, id: user.id, version: 1, format: :json, access_token: token.token
      #  json.should == JSON.parse(user.to_json)
      #end

    end

    context 'no valid access token' do
      it 'responds with 401 when unauthorized' do
        get :show, params: {id: user.id, version: 1}, format: :json
        response.status.should eq(401)
      end
    end

  end

end
