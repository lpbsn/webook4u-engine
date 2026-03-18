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

ActiveRecord::Schema[8.1].define(version: 2026_03_18_091500) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "bookings", force: :cascade do |t|
    t.datetime "booking_end_time"
    t.datetime "booking_expires_at"
    t.datetime "booking_start_time"
    t.string "booking_status"
    t.bigint "client_id", null: false
    t.string "confirmation_token"
    t.datetime "created_at", null: false
    t.string "customer_email"
    t.string "customer_first_name"
    t.string "customer_last_name"
    t.bigint "service_id", null: false
    t.string "stripe_payment_intent"
    t.string "stripe_session_id"
    t.datetime "updated_at", null: false
    t.index ["client_id", "booking_start_time"], name: "index_bookings_on_client_and_start_time_confirmed", unique: true, where: "((booking_status)::text = 'confirmed'::text)"
    t.index ["client_id"], name: "index_bookings_on_client_id"
    t.index ["confirmation_token"], name: "index_bookings_on_confirmation_token", unique: true
    t.index ["service_id"], name: "index_bookings_on_service_id"
  end

  create_table "clients", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.string "slug"
    t.datetime "updated_at", null: false
  end

  create_table "services", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.datetime "created_at", null: false
    t.integer "duration_minutes"
    t.string "name"
    t.integer "price_cents"
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_services_on_client_id"
  end

  add_foreign_key "bookings", "clients"
  add_foreign_key "bookings", "services"
  add_foreign_key "services", "clients"
end
