class DataController < ApplicationController
  def locations
    @locations=Location.all
    @attributes=["id","post_code","lat","lng"]
    respond_to do |format|
      format.html
      format.json { render json: Location.to_json}
    end
  end

  def location_weather
    @attributes=["record_time","rainfall","temperature","wind_dir","win_speed"]
    @location_id=params[:location_id]
    @l=Location.find_by_id(@location_id)
    unless @l.nil?
      @nearest_station=Station.closest(:origin => [@l.lat,@l.lng]).first
      @distances=@nearest_station.distance_from([@l.lat,@l.lng],:units=>:miles)
      @date=params[:date]
      t_array=@date.split(/-/).map{|d| d.to_i}

      begin
        query_time=DateTime.new(*t_array.reverse!)
      rescue ArgumentError
        query_time=nil
      end
      @wrecs=WeatherDataRecording.where(:recording_time=>query_time.at_beginning_of_day..query_time.at_end_of_day,:station_id=>@nearest_station.id)
    end
    respond_to do |format|
      format.html
      format.json { render json: weather_data_recording.to_json_by_location_and_date(@location_id,@date) }
    end
  end

  def postcode_weather
    @post_code=params[:post_code]
    @date=params[:date]
    respond_to do |format|
      format.html
      format.json { render json: Location.to_json_by_postcode_and_date(@post_code,@date) }
    end
  end

end
