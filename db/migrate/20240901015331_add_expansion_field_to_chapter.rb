class AddExpansionFieldToChapter < ActiveRecord::Migration[7.1]
  def change
    add_column :chapters, :expansion, :boolean, default: false
  end
end
