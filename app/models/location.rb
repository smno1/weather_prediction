require 'csv'

class Location < ActiveRecord::Base
  self.primary_key = :id
  acts_as_mappable

  def self.import_location_data
    location_array=Array.new
    CSV.read("vendor/location_csv/VIC_Post_Codes_Lat_Lon.csv",:headers=>true).each do |row|
      Location.create({:post_code=>row[0],:id=>row[1],:lat=>row[5].to_f,:lng=>row[6].to_f})
    end
  end
  
  #find nearby location e.g.
  #Location.within(50,:origin=>[-36.9,146.7])
end
