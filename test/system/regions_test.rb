require "application_system_test_case"

class RegionsTest < ApplicationSystemTestCase
  setup do
    @region = regions(:region_1)
  end

  test "visiting the index" do
    visit regions_url
    assert_selector "h1", text: "Regions"
  end

  test "should create region" do
    visit regions_url
    click_on "New region"

    click_on "Create Region"

    assert_text "Region was successfully created"
    click_on "Back"
  end

  test "should update Region" do
    visit region_url(@region)
    click_on "Edit this region", match: :first

    click_on "Update Region"

    assert_text "Region was successfully updated"
    click_on "Back"
  end

  test "should destroy Region" do
    visit region_url(@region)
    click_on "Destroy this region", match: :first

    assert_text "Region was successfully destroyed"
  end
end
