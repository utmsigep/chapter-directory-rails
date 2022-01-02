require "application_system_test_case"

class RegionsTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers

  setup do
    sign_in users(:admin)
    @region = regions(:region_1)
  end

  test "visiting the index" do
    visit admin_regions_url
    assert_selector "h1", text: "Regions"
  end

  test "should create region" do
    visit admin_regions_url
    click_on "New"

    fill_in "region_name", with: 'Test Region'
    fill_in "region_short_name", with: "T1"

    click_on "Create Region"

    assert_text "Region was successfully created"
  end

  test "should update Region" do
    visit admin_region_url(@region)
    click_on "Edit", match: :first

    click_on "Update Region"

    assert_text "Region was successfully updated"
  end

  test "should destroy Region" do
    visit admin_region_url(@region)
    click_on "Delete Region", match: :first

    assert_text "Region was successfully destroyed"
  end
end
