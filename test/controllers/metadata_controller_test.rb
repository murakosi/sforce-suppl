require 'test_helper'

class MetadataControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get metadata_show_url
    assert_response :success
  end

end
