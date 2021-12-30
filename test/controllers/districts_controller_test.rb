require "test_helper"

class DistrictsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @district = districts(:district_1)
  end

  test "should get index" do
    get admin_districts_url
    assert_response :success
  end

  test "should get new" do
    get new_admin_district_url
    assert_response :success
  end

  test "should create district" do
    assert_difference("District.count") do
      post admin_districts_url, params: { district: { name: 'Test Long Name', short_name: 'Test Short' } }
    end

    assert_redirected_to admin_district_url(District.last)
  end

  test "should show district" do
    get admin_district_url(@district)
    assert_response :success
  end

  test "should get edit" do
    get edit_admin_district_url(@district)
    assert_response :success
  end

  test "should update district" do
    patch admin_district_url(@district), params: { district: { name: 'Test Long Name', short_name: 'Test Short' } }
    assert_redirected_to admin_district_url(@district)
  end

  test "should destroy district" do
    assert_difference("District.count", -1) do
      delete admin_district_url(@district)
    end

    assert_redirected_to admin_districts_url
  end
end
