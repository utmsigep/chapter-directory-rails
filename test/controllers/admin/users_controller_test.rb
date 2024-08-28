require "test_helper"

class AdminUsersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:admin)
    sign_in users(:admin)
  end

  test "should get index" do
    get admin_users_url
    assert_response :success
  end

  test "should get show" do
    get admin_user_url(@user)
    assert_response :success
  end

  test "should get new" do
    get new_admin_user_url
    assert_response :success
  end

  test "should create user" do
    assert_difference('User.count') do
      post admin_users_url, params: { user: { email: 'user@example.com', role: 'editor', password: 'testing123', password_confirmation: 'testing123' } }
    end

    assert_redirected_to admin_user_url(User.last)
  end

  test "should show user" do
    get admin_user_url(@user)
    assert_response :success
  end

  test "should get edit" do
    get edit_admin_user_url(@user)
    assert_response :success
  end

  test "should update user" do
    patch admin_user_url(@user), params: { user: { email: 'user2@example.com' } }
    assert_redirected_to admin_user_url(@user)
  end

  test "should destroy user" do
    assert_difference('User.count', -1) do
      deleted_user = users(:deleteme)
      delete admin_user_url(deleted_user)
    end

    assert_redirected_to admin_users_url
  end

  test "should not destroy current user" do
    assert_difference('User.count', 0) do
      delete admin_user_url(@user)
    end

    assert_redirected_to admin_users_url
  end
end
