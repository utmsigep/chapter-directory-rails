class AddManpowerToChapters < ActiveRecord::Migration[7.0]
  def change
    add_column :chapters, :manpower, :integer, default: 0
  end
end
