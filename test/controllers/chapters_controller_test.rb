require "test_helper"

class ChaptersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @chapter = chapters(:tnkappa)
    @region = regions(:region_4)
    @district = districts(:district_17)
  end

  test "should get index" do
    get admin_chapters_url
    assert_response :success
  end

  test "should get new" do
    get new_admin_chapter_url
    assert_response :success
  end

  test "should create chapter" do
    assert_difference("Chapter.count") do
      post admin_chapters_url, params: { chapter: { name: 'Test Long Name', district_id: @district.id, region_id: @region.id } }
    end

    assert_redirected_to admin_chapter_url(Chapter.last)
  end

  test "should show chapter" do
    get admin_chapter_url(@chapter)
    assert_response :success
  end

  test "should get edit" do
    get edit_admin_chapter_url(@chapter)
    assert_response :success
  end

  test "should update chapter" do
    patch admin_chapter_url(@chapter), params: { chapter: { name: 'Test Long Name', district_id: @district.id, region_id: @region.id } }
    assert_redirected_to admin_chapter_url(@chapter)
  end

  test "should destroy chapter" do
    assert_difference("Chapter.count", -1) do
      delete admin_chapter_url(@chapter)
    end

    assert_redirected_to admin_chapters_url
  end
end
