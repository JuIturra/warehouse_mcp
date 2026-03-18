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

ActiveRecord::Schema[7.1].define(version: 2026_03_18_030254) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "containers", force: :cascade do |t|
    t.string "code"
    t.bigint "slot_id", null: false
    t.bigint "truck_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slot_id"], name: "index_containers_on_slot_id"
    t.index ["truck_id"], name: "index_containers_on_truck_id"
  end

  create_table "slots", force: :cascade do |t|
    t.bigint "yard_id", null: false
    t.integer "row"
    t.integer "column"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["yard_id"], name: "index_slots_on_yard_id"
  end

  create_table "trucks", force: :cascade do |t|
    t.string "plate"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "yards", force: :cascade do |t|
    t.string "name"
    t.integer "rows"
    t.integer "columns"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "containers", "slots"
  add_foreign_key "containers", "trucks"
  add_foreign_key "slots", "yards"
end
