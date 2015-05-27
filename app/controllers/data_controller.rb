class DataController < ApplicationController
  def locations
    @locations=Location.all
    @attributes=["id","post_code","lat","lng"]
    respond_to do |format|
      format.html
      format.json { render json: Location.to_json(@locations)}
    end
  end

  def location_weather
    @attributes=["record_time","rainfall","temperature","wind_dir","win_speed"]
    @location_id=params[:location_id]
    @l=Location.find(@location_id)
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
    @current_weather=WeatherDataRecording.find_by(:recording_time=>query_time,:station_id=>@nearest_station.id)

    respond_to do |format|
      format.html
      format.json { render json: weather_data_recording.to_json_by_location_and_date(@date,@wrecs,@current_weather) }
    end
  end

  def postcode_weather
    @post_code=params[:post_code]
    @location_ids = Location.where(:post_code=>@post_code)
    @date=params[:date]
    t_array=@date.split(/-/).map{|d| d.to_i}
    begin
      query_time=DateTime.new(*t_array.reverse!)
    rescue ArgumentError
      query_time=nil
    end
    
    @wrecs=Hash.new
    @location_ids.each do |l|
      nearest_station=Station.closest(:origin => [l.lat,l.lng]).first
      @wrecs[nearest_station]= WeatherDataRecording.where(:recording_time=>query_time.at_beginning_of_day..query_time.at_end_of_day,:station_id=>nearest_station.id)
    end
    
    
    respond_to do |format|
      format.html
      format.json { render json: Location.to_json_by_postcode_and_date(@date,@wrecs) }
    end
  end

end
