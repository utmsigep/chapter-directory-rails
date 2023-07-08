class AddRegionalDirectorToRegions < ActiveRecord::Migration[7.0]
  def change
    add_column :regions, :staff_name, :string
    add_column :regions, :staff_url, :string
  end
end
