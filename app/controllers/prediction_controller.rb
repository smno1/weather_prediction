class PredictionController < ApplicationController
  def postcode_weather
    @post_code=params[:post_code]
    @period=params[:period]
  end

  def coordinate_weather
    @lat=params[:lat]
    @long=params[:long]
    @station=Station.closest(:origin => [l.lat,l.lng]).first
    @distances=@station.distance_from([@lat,@long],:units=>:miles)
    @period=params[:period]
    @period_toi = @period.to_i
    DateTime dt=DateTime.now
    dt-=1.day

    x_data = []
    temp_y_data = []
    rain_y_data = []
    wind_dir_y_data = []
    wind_speed_y_data = []
    predict_temp = []
    predict_rain = []
    predict_win_dir = []
    predict_wind_speed = []

    wdrecs=WeatherDataRecording.where(:recording_time=>dt.at_beginning_of_day..dt.at_end_of_day, :station_id=>@station.id)
    wdrecs.each do |rec|
      rec.recording_time
      temp_y_data = rec.temperature_record.cel_degree
    end

    wdrecs=WeatherDataRecording.where(:recording_time=>dt.at_beginning_of_day..dt.at_end_of_day, :station_id=>@station.id)
    wdrecs.each do |rec|
      rec.recording_time
      rain_y_data = rec.rain_fall_records.precip_amount
    end

    wdrecs=WeatherDataRecording.where(:recording_time=>dt.at_beginning_of_day..dt.at_end_of_day, :station_id=>@station.id)
    wdrecs.each do |rec|
      rec.recording_time
      wind_dir_y_data = rec.wind_records.win_dir
    end

    wdrecs=WeatherDataRecording.where(:recording_time=>dt.at_beginning_of_day..dt.at_end_of_day, :station_id=>@station.id)
    wdrecs.each do |rec|
      rec.recording_time
      wind_speed_y_data = rec.wind_records.win_speed
    end

    preditUtil = PredictionUtil.new

    predict_temp = preditUtil.prediction(@station.name, x_data, temp_y_data, @period_toi)
    predict_rain = preditUtil.prediction(@station.name, x_data, rain_y_data, @period_toi)
    predict_win_dir = preditUtil.prediction(@station.name, x_data, predict_win_dir, @period_toi)
    predict_wind_speed = preditUtil.prediction(@station.name, x_data, predict_wind_speed, @period_toi)
    
  end
end
