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

ActiveRecord::Schema[8.1].define(version: 2026_03_11_000004) do
# Could not dump table "customers" because of following StandardError
#   Unknown type 'uuid' for column 'id'


# Could not dump table "line_items" because of following StandardError
#   Unknown type 'uuid' for column 'id'


# Could not dump table "orders" because of following StandardError
#   Unknown type 'uuid' for column 'customer_id'


# Could not dump table "products" because of following StandardError
#   Unknown type 'uuid' for column 'id'


  create_table "settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "currency", default: "USD", null: false
    t.boolean "maintenance_mode", default: false, null: false
    t.string "store_name", default: "Zodra Store", null: false
    t.string "timezone", default: "UTC", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "line_items", "orders"
  add_foreign_key "line_items", "products"
  add_foreign_key "orders", "customers"
end
