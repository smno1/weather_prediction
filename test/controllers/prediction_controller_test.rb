require 'test_helper'

class PredictionControllerTest < ActionController::TestCase
  test "should get postcode_weather" do
    get :postcode_weather
    assert_response :success
  end

  test "should get coordinate_weather" do
    get :coordinate_weather
    assert_response :success
  end

end
