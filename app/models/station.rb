require 'nokogiri'
require 'open-uri'

class Station < ActiveRecord::Base
  acts_as_mappable :distance_field_name => :distance
  def self.get_data
    doc = Nokogiri::HTML(open('http://www.bom.gov.au/vic/observations/vicall.shtml#WIM'))
    doc.css("#content").each do |x|
      station = x.css("tr")
      station.each do |y|
        temp = y.css("a").map { |x| x['href']}
        code = temp.join().match(/\.[0-9]{5}/).to_s
        if !code.empty?
          json_url = "http://www.bom.gov.au/fwo/IDV60801/IDV60801#{code}.json"
          result = JSON.parse(open(json_url).read)
          obs = result["observations"]
          weather_data = obs["data"]
          station = obs["header"][0]["name"]
          sta_id=Station.find_by(:name=>station).id
          weather_data.each do |data|
            time=BaseFunctionUtil.location_time_to_datetime data.fetch("local_date_time_full")
            #weather??
            wrec=WeatherDataRecording.where(:station_id=>sta_id,:recording_time=>time)
            if wrec.blank?
              wrec=WeatherDataRecording.create(:station_id=>sta_id,:recording_time=>time)
              TemperatureRecord.create(:cel_degree => data.fetch("air_temp"),:weather_data_recording_id=>wrec.id)
              RainFallRecord.create(:precip_amount=>data.fetch("rain_trace"),:weather_data_recording_id=>wrec.id)
              WindRecord.create(:win_dir =>BaseFunctionUtil.win_dir_to_number(data.fetch("wind_dir")), :win_speed=>data.fetch("wind_spd_kmh"),:weather_data_recording_id=>wrec.id)
            end
          end
        end
      end
    end
  end

  def self.get_station
    doc = Nokogiri::HTML(open("http://www.bom.gov.au/vic/observations/vicall.shtml"))
    doc.css("#content").each do |x|
      station = x.css("tr")
      station.each do |y|
        temp = y.css("a").text
        sta = temp if !temp.empty?
        b = y.css("a").map { |x| x['href']}
        if !b.empty?
          new_url = "http://www.bom.gov.au#{b.join()}"
          read = Nokogiri::HTML(open(new_url))
          lat = read.css(".stationdetails").css("td")[3].text[/[-0-9.]+/]
          lon = read.css(".stationdetails").css("td")[4].text[/[-0-9.]+/]
          Station.create(:name=>sta,:lat=>lat,:lng=>lon)
        end
      end
    end
  end

end
