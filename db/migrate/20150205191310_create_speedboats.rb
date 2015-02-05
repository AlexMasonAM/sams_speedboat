class CreateSpeedboats < ActiveRecord::Migration
  def change
    create_table :speedboats do |t|
      t.string :brand
      t.string :model_number
      t.string :image_url
      t.float :wholesale_price
      t.float :retail_price
      t.boolean :in_stock

      t.timestamps null: false
    end
  end
end
