class AddLocationToChapter < ActiveRecord::Migration[7.0]
  def change
    add_column :chapters, :location, :string
    add_column :chapters, :slc, :boolean
  end
end
