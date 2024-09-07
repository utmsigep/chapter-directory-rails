class AddCharterDateToChapters < ActiveRecord::Migration[7.1]
  def change
    add_column :chapters, :charter_date, :date
    add_column :chapters, :chapter_roll, :integer
  end
end
