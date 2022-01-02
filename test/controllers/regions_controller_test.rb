require "test_helper"

class RegionsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @region = regions(:region_1)
    sign_in users(:admin)
  end

  test "should get index" do
    get admin_regions_url
    assert_response :success
  end

  test "should get new" do
    get new_admin_region_url
    assert_response :success
  end

  test "should create region" do
    assert_difference("Region.count") do
      post admin_regions_url, params: { region: { name: 'Test Long Name', short_name: 'Test Short' } }
    end

    assert_redirected_to admin_region_url(Region.last)
  end

  test "should show region" do
    get admin_region_url(@region)
    assert_response :success
  end

  test "should get edit" do
    get edit_admin_region_url(@region)
    assert_response :success
  end

  test "should update region" do
    patch admin_region_url(@region), params: { region: { name: 'Test Long Name', short_name: 'Test Short' } }
    assert_redirected_to admin_region_url(@region)
  end

  test "should destroy region" do
    assert_difference("Region.count", -1) do
      delete admin_region_url(@region)
    end

    assert_redirected_to admin_regions_url
  end
end
