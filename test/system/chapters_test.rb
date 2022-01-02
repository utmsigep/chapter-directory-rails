require "application_system_test_case"

class ChaptersTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers

  setup do
    sign_in users(:admin)
    @chapter = chapters(:tnkappa)
  end

  test "visiting the index" do
    visit admin_chapters_url
    assert_selector "h1", text: "Chapters"
  end

  test "should create chapter" do
    visit admin_chapters_url
    click_on "New"

    fill_in 'chapter_name', with: "Test Chapter"

    click_on "Create Chapter"

    assert_text "Chapter was successfully created"
  end

  test "should update Chapter" do
    visit admin_chapter_url(@chapter)
    click_on "Edit", match: :first

    click_on "Update Chapter"

    assert_text "Chapter was successfully updated"
  end

  test "should destroy Chapter" do
    visit admin_chapter_url(@chapter)
    click_on "Delete Chapter", match: :first

    assert_text "Chapter was successfully destroyed"
  end
end
