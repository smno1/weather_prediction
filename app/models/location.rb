require 'csv'
require 'nokogiri'
require 'open-uri'
require 'json'

class Location < ActiveRecord::Base
  self.primary_key = :id
  acts_as_mappable

  def self.import_location_data
    location_array=Array.new
    CSV.read("vendor/location_csv/VIC_Post_Codes_Lat_Lon.csv",:headers=>true).each do |row|
      Location.create({:post_code=>row[0],:id=>row[1],:lat=>row[5].to_f,:lng=>row[6].to_f})
    end
  end
  
  def self.get_data
        
    name = []
    time = []
    rain_fall  = []
    temperature = []
    wind_speed = []
    wind_direction = []

    doc = Nokogiri::HTML(open(  'http://www.bom.gov.au/vic/observations/vicall.shtml#WIM'))
    
    doc.css("#content").each do |x|
      station = x.css("tr")
      station.each do |y|
        temp = y.css("a").map { |x| x['href']}
        code = temp.join().match(/\.[0-9]{5}/).to_s
        if !code.empty?
           json_url = "http://www.bom.gov.au/fwo/IDV60801/IDV60801#{code}.json"
           result = JSON.parse(open(json_url).read)
           a = result["observations"]
           b = a["data"]
               b.each do |data|
                 name << data.fetch("name")
                 time << data.fetch("local_date_time")
                 rain_fall << data.fetch("rain_trace")
                 temperature << data.fetch("air_temp")
                 wind_speed << data.fetch("wind_spd_kmh")
                 wind_direction << data.fetch("wind_dir")
               end
          end 
      end
    end
    print name
    puts
    print time
    puts
    print rain_fall
    puts
    print temperature
    puts 
    print wind_speed 
    puts 
    print wind_direction
    # still trying to get data from bom
  end


  #find nearby location e.g.
  #Location.within(50,:origin=>[-36.9,146.7])
  
  
  
  
  def self.to_json
    locations = Locations.all
    output_list = locations.map do |c|   
      {:id=>c.id, :lat=>c.lat,:lon=>c.lng,:last_update=>c.updated_at}
    end
    {:date=>Datetime.now,:locations=>output_list}
  end


  
  def self.to_json_by_postcode_and_date post_code,date
    output_list = Locations.where(:post_code=>post_code).map do |c|
      measurement_list= c.weather_data_recordings.where(:recording_time between date.at_the_begin_of_day .. date.at_the_end_the_day).map do |p|
        {:time=>p.recording_time,:temp=>p.temperature_record.cel_degree,:precip=>p.rain_fall_records.precip_amount,:wind_direction=>p.wind_records.win_dir,:wind_speed=>p.wind_records.win_speed}
      end  
     {:id=>c.id, :lat=>c.lat,:lon=>c.lng,:last_update=>c.updated_at,:measurements=>measurement_list}
    end
     {:date=>date,:locations=>output_list}
  end
  
  
end
