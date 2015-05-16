class CreateWindRecords < ActiveRecord::Migration
  def change
    create_table :wind_records do |t|
      t.float :win_dir
      t.float :win_speed
      t.references :weather_data_recording, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
