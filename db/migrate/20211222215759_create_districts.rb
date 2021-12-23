class CreateDistricts < ActiveRecord::Migration[7.0]
  def change
    create_table :districts do |t|
      t.string :name
      t.string :short_name
      t.integer :position
      t.timestampsra
    end
  end
end
