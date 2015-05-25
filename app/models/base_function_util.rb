module BaseFunctionUtil
  extend self
  def location_time_to_datetime location_time
    DateTime.new(location_time[0,4].to_i,location_time[4,2].to_i,location_time[6,2].to_i,location_time[8,2].to_i,location_time[10,2].to_i,location_time[12,2].to_i)
  end
end