class PredictionController < ApplicationController

  def postcode_weather
  	@post_code=params[:post_code]
    @period=params[:period]
  end

  def coordinate_weather
  	@lat=params[:lat]
  	@long=params[:long]
    @period=params[:period]
  end
end
