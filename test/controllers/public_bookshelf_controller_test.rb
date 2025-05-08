require "test_helper"

class PublicBookshelfControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get public_bookshelf_index_url
    assert_response :success
  end

  test "should get show" do
    get public_bookshelf_show_url
    assert_response :success
  end
end
