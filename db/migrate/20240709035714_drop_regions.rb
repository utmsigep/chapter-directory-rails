class DropRegions < ActiveRecord::Migration[7.1]
  def change
    drop_table :regions
  end
end
