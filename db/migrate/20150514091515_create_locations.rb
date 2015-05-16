class CreateLocations < ActiveRecord::Migration
  def change
    create_table :locations, {:id=>false} do |t|
      t.string :id, index: true, primary_key: true
      t.float :lat
      t.float :lng
      t.integer :post_code

      t.timestamps null: false
    end
  end
end
