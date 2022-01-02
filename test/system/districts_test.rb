require "application_system_test_case"

class DistrictsTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers

  setup do
    sign_in users(:admin)
    @district = districts(:district_1)
  end

  test "visiting the index" do
    visit admin_districts_url
    assert_selector "h1", text: "Districts"
  end

  test "should create district" do
    visit admin_districts_url
    click_on "New"

    fill_in "district_name", with: 'Test District'
    fill_in "district_short_name", with: "T1"

    click_on "Create District"

    assert_text "District was successfully created"
  end

  test "should update District" do
    visit admin_district_url(@district)
    click_on "Edit", match: :first

    click_on "Update District"

    assert_text "District was successfully updated"
  end

  test "should destroy District" do
    visit admin_district_url(@district)
    click_on "Delete District", match: :first

    assert_text "District was successfully destroyed"
  end
end
