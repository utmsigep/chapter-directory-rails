class SplitLocationIntoCityState < ActiveRecord::Migration[7.1]
  def change
    add_column :chapters, :city, :string
    add_column :chapters, :state, :string

    # Split the location into city and state
    execute <<-SQL.squish
      UPDATE chapters
      SET
        city = TRIM(SUBSTRING_INDEX(location, ',', 1)),
        state = TRIM(SUBSTRING_INDEX(location, ',', -1))
    SQL

    remove_column :chapters, :location
  end
end
