require "test_helper"

class AdminProfileControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:user)
    sign_in @user
  end

  test "should get profile edit" do
    get admin_profile_url
    assert_response :success
  end

  test "should update profile without password" do
    patch admin_profile_url, params: { user: { email: 'updated-user@example.org' } }

    assert_redirected_to admin_profile_url
    assert_equal 'updated-user@example.org', @user.reload.email
  end

  test "should require authentication" do
    sign_out @user

    get admin_profile_url
    assert_redirected_to new_user_session_url
  end
end
