require "test_helper"

class Admin::DashboardControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:admin)
    sign_in users(:admin)
  end

  test "should get index" do
    get admin_user_url(@user)
    assert_response :success
  end
end
