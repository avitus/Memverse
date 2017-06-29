require 'spec_helper'

describe UsersController do

  before(:each) do
    login_user
  end

  describe "GET 'show'" do

    it "should be successful" do
      get :show, params: {id: @user.id}
      response.should be_success
    end

    it "should find the right user" do
      get :show, params: {id: @user.id}
      assigns(:user).should == @user
    end

  end

  # ==============================================================================================
  # Updating reference score
  # ==============================================================================================
  describe "update_ref_grade" do

    context 'when logged in' do
      it "should save updated reference score" do
        post :update_ref_grade, params: {score: 75}, format: :json
        expect(response.status).to eq(200)
      end
    end

    context 'when logged out' do
      it "should redirect user" do
        sign_out @user
        post :update_ref_grade, params: {score: 75}, format: :json
        expect(response.status).to eq(401)
      end
    end

  end

  # ==============================================================================================
  # Updating accuracy score
  # ==============================================================================================
  describe "update_accuracy" do

    context 'when logged in' do
      it "should save updated accuracy score" do
        post :update_accuracy, params: {score: 75}, format: :json
        expect(response.status).to eq(200)
      end
    end

    context 'when logged out' do
      it "should redirect user" do
        sign_out @user
        post :update_accuracy, params: {score: 75}, format: :json
        expect(response.status).to eq(401)
      end
    end

  end

end
