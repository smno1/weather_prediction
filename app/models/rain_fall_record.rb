class RainFallRecord < ActiveRecord::Base
  belongs_to :weather_data_recording
end
