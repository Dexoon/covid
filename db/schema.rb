# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_04_15_182447) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "bids", force: :cascade do |t|
    t.bigint "region_id", null: false
    t.text "contact_info"
    t.string "aasm_state"
    t.string "type"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["region_id"], name: "index_bids_on_region_id"
  end

  create_table "messages", force: :cascade do |t|
    t.string "type"
    t.bigint "chat_id"
    t.integer "message_id"
    t.string "archmessage_type"
    t.bigint "archmessage_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["archmessage_type", "archmessage_id"], name: "index_messages_on_archmessage_type_and_archmessage_id"
  end

  create_table "positions", force: :cascade do |t|
    t.string "type"
    t.float "request", default: 0.0
    t.float "plan", default: 0.0
    t.float "produced", default: 0.0
    t.float "delivered", default: 0.0
    t.bigint "bid_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["bid_id"], name: "index_positions_on_bid_id"
  end

  create_table "regions", force: :cascade do |t|
    t.string "name"
    t.integer "code"
    t.bigint "chat_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "flood_chat_id"
  end

  create_table "reports", force: :cascade do |t|
    t.integer "order"
    t.bigint "region_id", null: false
    t.string "product", default: [], array: true
    t.string "photo", default: [], array: true
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["region_id"], name: "index_reports_on_region_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "type"
    t.string "name"
    t.string "username"
    t.integer "tg_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  add_foreign_key "bids", "regions"
  add_foreign_key "positions", "bids"
  add_foreign_key "reports", "regions"
end
