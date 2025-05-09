require "test_helper"

class SharedMemosControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get shared_memos_show_url
    assert_response :success
  end
end
