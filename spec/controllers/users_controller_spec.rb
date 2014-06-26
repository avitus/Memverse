require 'spec_helper'

describe UsersController do

  before(:each) do
    login_user
  end

  describe "GET 'show'" do

    it "should be successful" do
      get :show, :id => @user.id
      response.should be_success
    end

    it "should find the right user" do
      get :show, :id => @user.id
      assigns(:user).should == @user
    end

  end

  # ==============================================================================================
  # Updating reference score
  # ==============================================================================================
  describe "update_ref_grade" do

    context 'when logged in' do
      it "should save updated reference score" do
        post :update_ref_grade, :score => 75, :format => :json
        expect(response.status).to eq(200)
      end
    end

    context 'when logged out' do
      it "should redirect user" do
        sign_out @user
        post :update_ref_grade, :score => 75, :format => :json
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
        post :update_accuracy, :score => 75, :format => :json
        expect(response.status).to eq(200)
      end
    end

    context 'when logged out' do
      it "should redirect user" do
        sign_out @user
        post :update_accuracy, :score => 75, :format => :json
        expect(response.status).to eq(401)
      end
    end

  end

  # ==============================================================================================
  # Getting verse text
  # ==============================================================================================
  describe "get_verse" do

    context 'when logged in' do
      it "should default to verse in account" do
        @vs = FactoryGirl.create(:verse, book: "John", chapter: 1, versenum: 1,
                                         text: "In the beginning!")

        FactoryGirl.create(:memverse, verse: @vs, user: @user)

        get :get_verse, bk: "John", vs: 1, ch: 1
        response.should == "In the beginning!"
      end

      it "should fall back to verse in user's translation" do
        @vs = FactoryGirl.create(:verse, book: "John", chapter: 1, versenum: 1,
                                         text: "In the beginning...",
                                         translation: "NNV")

        @user.translation = "NNV"
        @user.save

        @user.has_verse?("John", 1, 1).should == nil

        get :get_verse, bk: "John", vs: 1, ch: 1
        response.should == "In the beginning..."
      end

      it "should gracefully fail" do
        Verse.where(book: "John", chapter: 1, versenum: 1).count.should == 0

        get :get_verse, bk: "John", vs: 1, ch: 1

        response.should == ""
        expect(response.status).to eq(200)
      end
    end

    context 'when logged out' do
      it "should redirect user" do
        sign_out @user
        get :get_verse
        expect(response.status).to eq(401)
      end
    end

  end

end
