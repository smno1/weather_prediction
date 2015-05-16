class CreateTemperatureRecords < ActiveRecord::Migration
  def change
    create_table :temperature_records do |t|
      t.float :cel_degree
      t.references :weather_data_recording, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
