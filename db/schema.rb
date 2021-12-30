# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2021_12_23_231607) do

  create_table "chapters", force: :cascade do |t|
    t.string "name"
    t.string "institution_name"
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.integer "region_id"
    t.integer "district_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "location"
    t.boolean "slc"
    t.string "website"
    t.index ["district_id"], name: "index_chapters_on_district_id"
    t.index ["region_id"], name: "index_chapters_on_region_id"
  end

  create_table "districts", force: :cascade do |t|
    t.string "name"
    t.string "short_name"
    t.integer "position", default: 0
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "regions", force: :cascade do |t|
    t.string "name"
    t.string "short_name"
    t.integer "position", default: 0
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

end
