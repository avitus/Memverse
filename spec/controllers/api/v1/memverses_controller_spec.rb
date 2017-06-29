require 'spec_helper'

describe Api::V1::MemversesController do

  before do
    allow(controller).to receive(:doorkeeper_token) {token}
  end

  let(:token) { double :acceptable? => true, :resource_owner_id => user.id }

  describe 'GET #index' do

    let!(:user)        { FactoryGirl.create(:user) }
    let!(:verse)       { FactoryGirl.create(:verse)}
    let!(:mv)          { FactoryGirl.create(:memverse, :user => user, :verse => verse)}

    it 'responds with 200' do
      get :index, params: {version: 1}, format: :json
      response.status.should eq(200)
    end

    # The API uses serializable_hash to create the response. It does not use to_json
    it 'returns user memory verses as json' do
      get :index, params: {version: 1}, format: :json
      expect(            json.first["id"           ]        ).to eq(mv.id)
      expect(            json.first["passage_id"   ]        ).to eq(mv.passage_id)
      expect(            json.first["ref"          ]        ).to eq(mv.ref)
      expect(            json.first["user_id"      ]        ).to eq(mv.user_id)
      expect(            json.first["efactor"      ].to_f   ).to eq(mv.efactor)
      expect(            json.first["test_interval"]        ).to eq(mv.test_interval)
      expect(            json.first["ref_interval" ]        ).to eq(mv.ref_interval)
      expect(            json.first["rep_n"        ]        ).to eq(mv.rep_n)
      expect( Date.parse(json.first["next_test"    ])       ).to eq(mv.next_test)
      expect( Date.parse(json.first["next_ref_test"])       ).to eq(mv.next_ref_test)
      expect(            json.first["verse"]["id"         ] ).to eq(mv.verse.id)
      expect(            json.first["verse"]["translation"] ).to eq(mv.verse.translation)
      expect(            json.first["verse"]["book_index" ] ).to eq(mv.verse.book_index)
      expect(            json.first["verse"]["book"       ] ).to eq(mv.verse.book)
      expect(            json.first["verse"]["chapter"    ] ).to eq(mv.verse.chapter)
      expect(            json.first["verse"]["versenum"   ] ).to eq(mv.verse.versenum)
      expect(            json.first["verse"]["text"       ] ).to eq(mv.verse.text)

      # This doesn't work as the API returns a different date format than calling serializable hash directly
      # expect( json.first).to eq(mv.serializable_hash)

    end

  end

  describe 'POST #create (with scopes)' do

    let!(:user)        { FactoryGirl.create(:user) }
    let!(:verse)       { FactoryGirl.create(:verse)}

    it 'creates the memverse' do
      expect {
        post :create, params: {id: verse.id, version: 1}, format: :json
      }.to change(Memverse, :count).by(1)
      response.status.should eq(201)
      json["verse"]["id"].should == verse.id
    end
  end

  describe 'PUT #update' do

    let!(:user)        { FactoryGirl.create(:user) }
    let!(:verse)       { FactoryGirl.create(:verse)}
    let!(:mv)          { FactoryGirl.create(:memverse, :user => user, :verse => verse)}

    it 'updates the memverse' do
      put :update, params: {id: mv.id, q: 5, version: 1}, format: :json
      response.status.should eq(200)
      json["test_interval"].should         == 4
      json["efactor"].to_f.should          == 2.1
      json["rep_n"].should                 == 2
      json["ref_interval"].should          == 6      # Don't make changes to the reference interval 
      Date.parse(json["next_test"]).should == Date.today + 4
    end

    it 'increases the reference interval correctly' do
      put :update, params: {id: mv.id, ref_recalled: "true", version: 1}, format: :json
      response.status.should eq(200)
      json["ref_interval"].should              == 9
      json["test_interval"].should             == 1   # Don't make changes to the test_interval
      Date.parse(json["next_ref_test"]).should == Date.today + 9
    end

    it 'decreases the reference interval correctly' do
      put :update, params: {id: mv.id, ref_recalled: "false", version: 1}, format: :json
      response.status.should eq(200)
      json["ref_interval"].should              == 4
      json["test_interval"].should             == 1   # Don't make changes to the test_interval
      Date.parse(json["next_ref_test"]).should == Date.today + 4
    end
  end

  describe 'DELETE #destroy' do

    let!(:user)        { FactoryGirl.create(:user) }
    let!(:verse)       { FactoryGirl.create(:verse)}
    let!(:mv)          { FactoryGirl.create(:memverse, :user => user, :verse => verse)}

    it 'deletes the memverse' do
      expect {
        delete :destroy, params: {id: mv.id, version: 1}, format: :json
      }.to change(Memverse, :count).by(-1)
      response.status.should eq (204)  # server executed the request but body of response contains no data
    end
  end

end