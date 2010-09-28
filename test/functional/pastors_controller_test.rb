require 'test_helper'

class PastorsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:pastors)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create pastor" do
    assert_difference('Pastor.count') do
      post :create, :pastor => { }
    end

    assert_redirected_to pastor_path(assigns(:pastor))
  end

  test "should show pastor" do
    get :show, :id => pastors(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => pastors(:one).to_param
    assert_response :success
  end

  test "should update pastor" do
    put :update, :id => pastors(:one).to_param, :pastor => { }
    assert_redirected_to pastor_path(assigns(:pastor))
  end

  test "should destroy pastor" do
    assert_difference('Pastor.count', -1) do
      delete :destroy, :id => pastors(:one).to_param
    end

    assert_redirected_to pastors_path
  end
end
