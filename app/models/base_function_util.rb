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
  
  def number_to_win_dir number
      case number
           when 0
             number = "N"
           when 0.01..44.99
             number = "NNE"
           when 45
             number = "NE"
           when 45.01..89.99
             number  = "ENE"
           when 90
             number  = "E"
           when 90.01..134.99
             number  = "ESE"
           when 135
             number = "SE"
           when 135.01..179.99
             number = "SSE"
           when 180
             number  = "S"
           when 180.01..224.99
             number  = "SSW"
           when 225
             number  = "SW"
           when 225.01..269.99
             number = "WSW"
           when 270
             number  = "W"
           when 270.01..314.99
             number  = "WNW"
           when 315
             number = "NW"
           when 315.01..359.99
             number  = "NNW"
           else 
             number  =  "-" 
           end
      end
end