require 'test_helper'

class DescriberControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get describer_show_url
    assert_response :success
  end

end
