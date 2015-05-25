class PredictionController < ApplicationController

  def postcode_weather
  	@post_code=params[:post_code]
    @period=params[:period]
  end

  def coordinate_weather
  	@lat=params[:lat]
  	@long=params[:long]
    @location=Location.closest(:origin => [l.lat,l.lng]).first
    @distances=@location.distance_from([@lat,@long],:units=>:miles)
    @period=params[:period]
  end
end
