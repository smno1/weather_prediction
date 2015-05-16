class CreateLocations < ActiveRecord::Migration
  def change
    create_table :locations, {:id=>false} do |t|
      t.string :id, index: true, primary_key: true
      t.string :lat
      t.string :long
      t.integer :post_code

      t.timestamps null: false
    end
  end
end
