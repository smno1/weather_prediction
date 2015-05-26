module BaseFunctionUtil
  extend self
  def location_time_to_datetime location_time
    DateTime.new(location_time[0,4].to_i,location_time[4,2].to_i,location_time[6,2].to_i,location_time[8,2].to_i,location_time[10,2].to_i,location_time[12,2].to_i)
  end
  
  def win_dir_to_number dir
        case dir
            when "N"
              dir = 0
            when "NNE"
              dir = 20
            when "NE"
              dir = 45
            when "ENE"
              dir = 60
            when "E" 
              dir = 90
            when "ESE" 
              dir = 120 
            when "SE"
              dir = 135
            when "SSE"
              dir = 140 
            when "S" 
              dir = 180
            when "SSW"
              dir = 200
            when "SW"
              dir = 225
            when "WSW"
              dir = 250
            when "W" 
              dir = 270
            when "WNW"
              dir = 300
            when "NW"
              dir = 315
            when "NNW"
              dir = 340
            else 
              dir = 0
        end
  end 
end