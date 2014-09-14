require 'spec_helper'

describe Api::V1::TranslationsController do

  let!(:application) { Doorkeeper::Application.create!(:name => "MyApp", :redirect_uri => "http://app.com") } # OAuth application
  let!(:user)        { FactoryGirl.create(:user) }
  let!(:token)       { Doorkeeper::AccessToken.create! :application_id => application.id, :resource_owner_id => user.id }

  describe 'GET #index' do

    it 'responds with 200' do
      get :index, :version => 1, :format => :json, :access_token => token.token
      response.status.should eq(200)
    end

    it 'returns translations as json' do
      get :index, :version => 1, :format => :json, :access_token => token.token
      json.should == JSON.parse(Translation.for_api.to_json)
    end

    it 'responds with 401 when unauthorized' do
      token.stub :accessible? => false
      get :index, :version => 1, :format => :json
      response.status.should eq(401)
    end
  end

  # describe 'GET #show' do

  #   it 'provides the translation name' do
  #     get :show, :id => "ESV", :version => 1, :format => :json, :access_token => token.token
  #     #get :show, :id => "ESV", :version => 1, :format => :json, :access_token => token.token

  #     response.status.should eq(200)
  #     response.should == JSON.parse(TRANSLATIONS[:ESV].to_json)
  #   end

  #   it 'returns nil for invalid translation abbreviation' do
  #     get :show, :id => "ESV", :version => 1, :format => :json, :access_token => token.token

  #     response.status.should eq(200)
  #     response.should == nil.to_s
  #   end
  # end

end
