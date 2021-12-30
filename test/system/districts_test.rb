require "application_system_test_case"

class DistrictsTest < ApplicationSystemTestCase
  setup do
    @district = districts(:district_1)
  end

  test "visiting the index" do
    visit admin_districts_url
    assert_selector "h1", text: "Districts"
  end

  test "should create district" do
    visit admin_districts_url
    click_on "New district"

    click_on "Create District"

    assert_text "District was successfully created"
    click_on "Back"
  end

  test "should update District" do
    visit admin_district_url(@district)
    click_on "Edit this district", match: :first

    click_on "Update District"

    assert_text "District was successfully updated"
    click_on "Back"
  end

  test "should destroy District" do
    visit admin_district_url(@district)
    click_on "Destroy this district", match: :first

    assert_text "District was successfully destroyed"
  end
end
