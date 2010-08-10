require 'test_helper'

class QuestsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:quests)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create quest" do
    assert_difference('Quest.count') do
      post :create, :quest => { }
    end

    assert_redirected_to quest_path(assigns(:quest))
  end

  test "should show quest" do
    get :show, :id => quests(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => quests(:one).to_param
    assert_response :success
  end

  test "should update quest" do
    put :update, :id => quests(:one).to_param, :quest => { }
    assert_redirected_to quest_path(assigns(:quest))
  end

  test "should destroy quest" do
    assert_difference('Quest.count', -1) do
      delete :destroy, :id => quests(:one).to_param
    end

    assert_redirected_to quests_path
  end
end
