class PredictionController < ApplicationController
  def postcode_weather
    @post_code=params[:post_code]
    @period=params[:period]
    @period_toi = @period.to_i
    dt=DateTime.now
    dt-=1.day
    @locations = Location.where(:post_code=>@post_code)

    #return hash in the form of? {"station1" => {"temperature" => [[1,2,3], [1,2,3]], "rain" => [[1,2,3],[1,2,3]]}, "station2" => {"temperature" => [[1,2,3], [1,2,3]], "rain" => [[1,2,3],[1,2,3]]}...}
    @stations_prediction_Hash = Hash.new
    @locations.each do |l|
      lat=l.lat
      lng=l.lng
      station=Station.closest(:origin => [lat,lng]).first
      distances=station.distance_from([lat,lng],:units=>:miles)
      @stations_prediction_Hash[l.id] = get_prediction(distances, dt, station, @period_toi)
    end

    respond_to do |format|
      format.html
      format.json { render json: weather_data_recording.to_json_by_postcode_and_period(@period_toi,@station.name,predict_temp,predict_rain,predict_win_dir,predict_wind_speed)}
    end
  end

  def coordinate_weather
    @columns=["prediction","temperature","rain","wind_dir","wind_speed"]
    @lat=params[:lat]
    @long=params[:long]
    @station=Station.closest(:origin => [@lat,@long]).first
    @distances=@station.distance_from([@lat,@long],:units=>:miles)
    @period=params[:period]

    @period_toi = @period.to_i
    dt=DateTime.now
    dt-=1.day

    @return_prediction = Hash.new
    @return_prediction = get_prediction(@distances, dt, @station, @period_toi)


    #get the prediction of temperature, rain and wind in the form of [[10,20,30], [0.9,0.8,0.7]]
    # @predict_rain = preditUtil.prediction(@station.name, x_formated_time, rain_y_data, @period_toi, "rain")
    # @predict_win_dir = preditUtil.prediction(@station.name, x_formated_time, wind_dir_y_data, @period_toi, "wind_dir")
    # @predict_wind_speed = preditUtil.prediction(@station.name, x_formated_time, wind_speed_y_data, @period_toi, "wind_speed")
    respond_to do |format|
      format.html
      format.json { render json: WeatherDataRecording.to_json_by_lat_long_and_period(@period_toi,@lat,@long,
        @return_prediction["temperature"],@return_prediction["rain"],@return_prediction["wind_dir"],@return_prediction["wind_speed"])}
    end
  end

  def get_prediction(distance, dt, station, period_toi)
    deduction_prob = 100000
    return_prediction = Hash.new

    x_data = []
    x_data_test = []

    x_formated_time = []
    temp_y_data = []
    rain_y_data = []
    wind_dir_y_data = []
    wind_speed_y_data = []
    predict_temp = []
    predict_rain = []
    predict_win_dir = []
    predict_wind_speed = []

    wdrecs=WeatherDataRecording.where(:recording_time=>dt.at_beginning_of_day..dt.at_end_of_day, :station_id=>station.id)
    wdrecs.each do |rec|
      x_data << rec.recording_time
      temp_y_data << rec.temperature_record.cel_degree
    end

    wdrecs=WeatherDataRecording.where(:recording_time=>dt.at_beginning_of_day..dt.at_end_of_day, :station_id=>station.id)
    wdrecs.each do |rec|
      rain_y_data << rec.rain_fall_record.precip_amount
    end

    wdrecs=WeatherDataRecording.where(:recording_time=>dt.at_beginning_of_day..dt.at_end_of_day, :station_id=>station.id)
    wdrecs.each do |rec|
      wind_dir_y_data << rec.wind_record.win_dir
    end

    wdrecs=WeatherDataRecording.where(:recording_time=>dt.at_beginning_of_day..dt.at_end_of_day, :station_id=>station.id)
    wdrecs.each do |rec|
      wind_speed_y_data << rec.wind_record.win_speed
    end

    #turn the time into required form
    x_data.each do |time|
      x_formated_time << time.hour + time.min/60.0
    end

    puts "=====================formated time================================"
    puts x_formated_time.inspect
    puts "=====================formated time================================"

    puts "=====================formated time================================"
    puts temp_y_data.inspect
    puts "=====================formated time================================"

    # i = 1
    # while i < 49
    # x_data_test << i
    # i=i+1
    # end

    preditUtil = PredictionUtil.new
    # return a hash contains the prediction of temperature, rain, wind and their corresponding probability
    # in the form of {:temperature [[10,20,30], [0.9,0.8,0.7]], :rain [[10,20,30], [0.9,0.8,0.7]], :wind_dir [[10,20,30], [0.9,0.8,0.7]], :wind_speed [[10,20,30], [0.9,0.8,0.7]]}
    return_prediction = preditUtil.prediction(station.name, x_formated_time, temp_y_data, rain_y_data, wind_dir_y_data, wind_speed_y_data, period_toi)
    return_prediction = return_prediction.merge(return_prediction){|k,v| v.collect{|x| x.collect{|y| ((y - distance/deduction_prob).abs).round(3)}}}

  end

end
