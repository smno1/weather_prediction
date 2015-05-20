class WeatherDataRecording < ActiveRecord::Base
  belongs_to :location

  def self.to_json_by_location_and_date location,date
    record =  Weather_data_recordings.find_by(location_id=>location,recording_time=>date.currentTime).temperature_recordings
    output_list= Weather_data_recordings.where(location_id=>location,recording_time=>date)
    {:date=>date, :current_temp=>record.cel_degree, :current_cond=>record.condition,:measurements=>output_list}
    #{date=>@date, current_temp=>temperature_record.find_by(:weather_data_recording_id=>record).cel_degree, current_cond=>"",measurements=>output_list}
  end

  
  
  
  
end
