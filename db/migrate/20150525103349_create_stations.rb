class CreateStations < ActiveRecord::Migration
  def change
    create_table :stations do |t|
      t.string :name
      t.float :lat
      t.float :lng
      t.float :distance

      t.timestamps null: false
    end
  end
end
