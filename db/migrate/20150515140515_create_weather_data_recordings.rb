class CreateWeatherDataRecordings < ActiveRecord::Migration
  def change
    create_table :weather_data_recordings do |t|
      t.string :condition
      t.references :station, index: true, foreign_key: true
      t.datetime :recording_time
      t.timestamps null: false
    end
  end
end
