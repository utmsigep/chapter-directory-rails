class DropRegionFromChapters < ActiveRecord::Migration[7.1]
  def change
    remove_column :chapters, :region_id
    remove_index :chapters, name: :index_chapters_on_region_id
  end
end
