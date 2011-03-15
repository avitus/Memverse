require 'test_helper'

class UberversesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:uberverses)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create uberverse" do
    assert_difference('Uberverse.count') do
      post :create, :uberverse => { }
    end

    assert_redirected_to uberverse_path(assigns(:uberverse))
  end

  test "should show uberverse" do
    get :show, :id => uberverses(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => uberverses(:one).to_param
    assert_response :success
  end

  test "should update uberverse" do
    put :update, :id => uberverses(:one).to_param, :uberverse => { }
    assert_redirected_to uberverse_path(assigns(:uberverse))
  end

  test "should destroy uberverse" do
    assert_difference('Uberverse.count', -1) do
      delete :destroy, :id => uberverses(:one).to_param
    end

    assert_redirected_to uberverses_path
  end
end
