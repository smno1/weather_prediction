class CreateWeatherDataRecordings < ActiveRecord::Migration
  def change
    create_table :weather_data_recordings do |t|
      t.string :condition
      t.references :location, type: "string", index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
