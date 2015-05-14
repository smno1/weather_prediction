class DataController < ApplicationController
  
  def locations
    
  end

  def location_weather
    @location_id=params[:location_id]
    @date=params[:date]
  end

  def postcode_weather
    @post_code=params[:post_code]
    @date=params[:date]
  end
  
end
