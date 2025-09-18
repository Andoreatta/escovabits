require "test_helper"

class CompilerControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get compiler_index_url
    assert_response :success
  end
end
