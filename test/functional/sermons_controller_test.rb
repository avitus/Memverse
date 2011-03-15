require 'test_helper'

class SermonsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:sermons)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create sermon" do
    assert_difference('Sermon.count') do
      post :create, :sermon => { }
    end

    assert_redirected_to sermon_path(assigns(:sermon))
  end

  test "should show sermon" do
    get :show, :id => sermons(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => sermons(:one).to_param
    assert_response :success
  end

  test "should update sermon" do
    put :update, :id => sermons(:one).to_param, :sermon => { }
    assert_redirected_to sermon_path(assigns(:sermon))
  end

  test "should destroy sermon" do
    assert_difference('Sermon.count', -1) do
      delete :destroy, :id => sermons(:one).to_param
    end

    assert_redirected_to sermons_path
  end
end
