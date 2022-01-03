require "test_helper"

class MapControllerTest < ActionDispatch::IntegrationTest
  test "should be redirected to home page" do
    get map_index_url
    assert_redirected_to '/'
  end

  test "should get data" do
    get map_data_url(format: 'json')
    assert_response :success
  end
end
