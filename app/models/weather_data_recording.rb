class WeatherDataRecording < ActiveRecord::Base
   belongs_to :station
  has_one :rain_fall_record
  has_one :temperature_record
  has_one :wind_record
  
  def get_wind_dir
    BaseFunctionUtil.number_to_win_dir self.wind_record.win_dir
  end

  def self.to_json_by_location_and_date date,w_record,w_current
    output_list= w_record.map do |p|
      {:time=>p.recording_time,:temp=>p.temperature_record.cel_degree,:precip=>p.rain_fall_record.precip_amount,:wind_direction=>p.get_wind_dir,:wind_speed=>p.wind_record.win_speed}
    end
    if(w_current.blank?)
     {:date=>date.strftime("%d-%m-%Y"), :current_temp=>"", :current_cond=>"",:measurements=>output_list}
    else  
     {:date=>date.strftime("%d-%m-%Y"), :current_temp=>w_current['temperature'], :current_cond=>w_current['summary'],:measurements=>output_list}
    end
  end
  
  def self.to_json_by_postcode_and_period period,post_code,predict_temp,predict_rain,predict_win_dir,predict_wind_speed
      return_hash=Hash.new
      time = Time.now
      i=0
      0.step(period-10,10) do |t|
        return_hash[t]={:time=>(time+(60*t)).strftime("%H:%M%P %d-%m-%Y"),:rain=>{:value=>predict_rain[0][i],:probability=>predict_rain[1][i]},:temp=>{:value=>predict_temp[0][i],:probability=>predict_temp[1][i]},:wind_speed=>{:value=>predict_wind_speed[0][i],:probability=>predict_wind_speed[1][i]},:wind_direction=>{:value=>predict_win_dir[0][i],:probability=>predict_win_dir[1][i]}}
        i+=1
      end
      {:postcode=>post_code,:predictions=>return_hash}   
  end
  
  
  def self.to_json_by_lat_long_and_period period,lat,long,predict_temp,predict_rain,predict_win_dir,predict_wind_speed
      return_hash=Hash.new
      time = Time.now
      i=0
      0.step(period-10,10) do |t|
        return_hash[t]={:time=>(time+(60*t)).strftime("%H:%M%P %d-%m-%Y"),:rain=>{:value=>predict_rain[0][i],:probability=>predict_rain[1][i]},
        :temp=>{:value=>predict_temp[0][i],:probability=>predict_temp[1][i]},:wind_speed=>{:value=>predict_wind_speed[0][i],:probability=>predict_wind_speed[1][i]},
        :wind_direction=>{:value=>(BaseFunctionUtil.number_to_win_dir predict_win_dir[0][i]),:probability=>predict_win_dir[1][i]}}
        i+=1
      end
      {:lattitude=>lat,:longitude=>long,:predictions=>return_hash}
  end
  
  
  
 
#  def search_past24 location_id
#    Weather_data_recordings.where(location_id=>location,recording_time=>(Time.now.beginning_of_day - 1.day)..Time.now.beginning_of_day).map do |a|
#      @tem_x << a.recording_time
#      @tem_y << a.temperature_records.cel_degree
#  end
  
  
  
end
