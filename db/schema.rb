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

ActiveRecord::Schema[8.0].define(version: 2026_02_20_091127) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "feature_flags", force: :cascade do |t|
    t.string "name", null: false
    t.boolean "global_default_state", default: false, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_feature_flags_on_name", unique: true
  end

  create_table "group_overrides", force: :cascade do |t|
    t.bigint "feature_flag_id", null: false
    t.string "group_id", null: false
    t.boolean "enabled", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["feature_flag_id", "group_id"], name: "index_group_overrides_on_feature_flag_id_and_group_id", unique: true
    t.index ["feature_flag_id"], name: "index_group_overrides_on_feature_flag_id"
  end

  create_table "region_overrides", force: :cascade do |t|
    t.bigint "feature_flag_id", null: false
    t.string "region", null: false
    t.boolean "enabled", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["feature_flag_id", "region"], name: "index_region_overrides_on_feature_flag_id_and_region", unique: true
    t.index ["feature_flag_id"], name: "index_region_overrides_on_feature_flag_id"
  end

  create_table "user_overrides", force: :cascade do |t|
    t.bigint "feature_flag_id", null: false
    t.string "user_id", null: false
    t.boolean "enabled", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["feature_flag_id", "user_id"], name: "index_user_overrides_on_feature_flag_id_and_user_id", unique: true
    t.index ["feature_flag_id"], name: "index_user_overrides_on_feature_flag_id"
  end

  add_foreign_key "group_overrides", "feature_flags"
  add_foreign_key "region_overrides", "feature_flags"
  add_foreign_key "user_overrides", "feature_flags"
end
