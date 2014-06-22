require 'spec_helper'

describe Api::V1::VersesController do

  describe 'GET #show' do

    let!(:application) { Doorkeeper::Application.create!(name: "MyApp", redirect_uri: "http://app.com") } # OAuth application
    let!(:user)        { FactoryGirl.create(:user) }
    let!(:token)       { Doorkeeper::AccessToken.create! application_id: application.id, resource_owner_id: user.id }
    let!(:verse)       { FactoryGirl.create(:verse)}

    it 'responds with 200' do
      get :show, id: verse.id, version: 1, format: :json, access_token: token.token
      response.status.should eq(200)
    end

    it 'returns a verse in JSON format' do
      get :show, id: verse.id, version: 1, format: :json, access_token: token.token
      json["text"].should == JSON.parse(verse.to_json)["text"]
    end

    it 'responds with 401 when unauthorized' do
      token.stub :accessible? => false
      get :show, id: verse.id, version: 1, format: :json
      response.status.should eq(401)
    end
  end

  describe 'GET #lookup' do

    let!(:application) { Doorkeeper::Application.create!(name: "MyApp", redirect_uri: "http://app.com") } # OAuth application
    let!(:user)        { FactoryGirl.create(:user) }
    let!(:token)       { Doorkeeper::AccessToken.create! application_id: application.id, resource_owner_id: user.id }
    let!(:verse)       { FactoryGirl.create(:verse)}

    it 'lookups a verse' do
      get :lookup, tl: 'NIV', bk: 'Galatians', ch: 5, vs: 22,version: 1, format: :json, access_token: token.token
      response.status.should eq(200)
      puts json["text"]
      json["text"].should == 'But the fruit of the Spirit is love, joy, peace, patience, kindness, goodness, faithfulness,'
    end

  end

end
