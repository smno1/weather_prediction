class WeatherDataRecording < ActiveRecord::Base
   belongs_to :station
  has_one :rain_fall_record
  has_one :temperature_record
  has_one :wind_record
  


  # def self.to_json_by_location_and_date location,date
    # record =  Weather_data_recordings.find_by(location_id=>location,recording_time=>date.currentTime).temperature_records
    # output_list= Weather_data_recordings.where(location_id=>location,recording_time=>date).map do |p|
      # {:time=>p.recording_time,:temp=>p.temperature_record.cel_degree,:precip=>p.rain_fall_records.precip_amount,:wind_direction=>p.wind_records.win_dir,:wind_speed=>p.wind_records.win_speed}
    # end
    # {:date=>date, :current_temp=>record.cel_degree, :current_cond=>record.condition,:measurements=>output_list}
  # end
#   
  # def self.to_json_by_postcode_and_period postcode,period
      # return_hash=Hash.new
      # location_id=Locations.find_by(post_code=>postcode).id
      # time = Time.new
      # #search_past24 location_id
      # if(period.eql?("10"||"30"||"60"||"120"||"180")
        # period.step(0,180) do |t|
        # return_hash[t]={:time=>(time+(600*t)).strftime("%H:%M%P %d-%m-%Y"),:rain=>{:value=>,:probability=>},:temp=>{:value=>,:probability=>},:wind_speed=>{:value=>,:probability=>},:wind_direction=>{:value=>,:probability=>}}
        # end
        # {:location_id=>location_id,:predictions=>return_hash}
      # else
        # puts "You can only choose the period from 10,30,60,120,180."
  # end
#   
#   
  # def self.to_json_by_lat_long_and_period lat,long,period
      # return_hash=Hash.new
      # location_id=Locations.find_by(lat=>lat AND lng=>long).id
      # time = Time.new
      # #search_past24 location_id
      # if(period.eql?("10"||"30"||"60"||"120"||"180")
        # period.step(0,180) do |t|
        # return_hash[t]={:time=>(time+(600*t)).strftime("%H:%M%P %d-%m-%Y"),:rain=>{:value=>,:probability=>},:temp=>{:value=>,:probability=>},:wind_speed=>{:value=>,:probability=>},:wind_direction=>{:value=>,:probability=>}}
        # end
      # {:lattitude=>lat,:longitude=>long,:predictions=>return_hash}
      # else
        # puts "You can only choose the period from 10,30,60,120,180."
#   
  # end
  
  
  
 
#  def search_past24 location_id
#    Weather_data_recordings.where(location_id=>location,recording_time=>(Time.now.beginning_of_day - 1.day)..Time.now.beginning_of_day).map do |a|
#      @tem_x << a.recording_time
#      @tem_y << a.temperature_records.cel_degree
#  end
  
  
  
end
