class CreateRainFallRecords < ActiveRecord::Migration
  def change
    create_table :rain_fall_records do |t|
      t.float :precip_amount
      t.references :weather_data_recording, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
