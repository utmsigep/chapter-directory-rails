class CreateChapters < ActiveRecord::Migration[7.0]
  def change
    create_table :chapters do |t|
      t.string :name
      t.string :short_name
      t.string :institution_long_name
      t.string :institution_short_name
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.references :region
      t.references :district
      t.timestamps
    end
  end
end
