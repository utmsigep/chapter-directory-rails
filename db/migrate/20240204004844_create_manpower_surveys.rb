class CreateManpowerSurveys < ActiveRecord::Migration[7.0]
  def change
    create_table :manpower_surveys, primary_key: [:chapter_id, :survey_date] do |t|
      t.integer 'chapter_id'
      t.date 'survey_date'
      t.integer 'manpower'
    end
  end
end
