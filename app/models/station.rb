class Station < ActiveRecord::Base
  acts_as_mappable :distance_field_name => :distance
  
  def self.get_data
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
          c = a["header"]
          puts "======5 c============"
          puts c.first(5)
          puts b.first
        # c.each do |station|
        # Station.create(:station_name =>station.fetch("name"))
        # end

        # b.each do |data|
        # TemperatureRecord.create(:cel_degree => data.fetch("air_temp"))
        # RainFallRecord.create(:precip_amount=>data.fetch("rain_trace"))
        # WindRecord.create(:win_dir =>data.fetch("wind_dir"), :win_speed=>data.fetch("wind_dir"))
        # end
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
