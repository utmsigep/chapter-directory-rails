class AddStatusToChapter < ActiveRecord::Migration[7.0]
  def change
    add_column :chapters, :status, :boolean
  end
end
