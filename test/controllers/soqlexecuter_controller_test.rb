require 'test_helper'

class SoqlexecuterControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get soqlexecuter_index_url
    assert_response :success
  end

  test "should get show" do
    get soqlexecuter_show_url
    assert_response :success
  end

end
