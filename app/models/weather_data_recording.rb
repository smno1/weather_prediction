class WeatherDataRecording < ActiveRecord::Base
  belongs_to :location

  def self.to_json_by_location_and_date location,date
    record =  Weather_data_recordings.find_by(location_id=>location,recording_time=>date.currentTime).temperature_recordings
    output_list= Weather_data_recordings.where(location_id=>location,recording_time=>date).map do |p|
      {:time=>p.recording_time,:temp=>p.temperature_record.cel_degree,:precip=>p.rain_fall_records.precip_amount,:wind_direction=>p.wind_records.win_dir,:wind_speed=>p.wind_records.win_speed}
    end
    {:date=>date, :current_temp=>record.cel_degree, :current_cond=>record.condition,:measurements=>output_list}
  end

end
