class AddStatusToRegions < ActiveRecord::Migration[7.0]
  def change
    add_column :regions, :status, :boolean, default: true
  end
end
