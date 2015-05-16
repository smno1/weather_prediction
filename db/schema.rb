# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150516005454) do

  create_table "locations", id: false, force: :cascade do |t|
    t.string   "id"
    t.string   "lat"
    t.string   "long"
    t.integer  "post_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "locations", ["id"], name: "index_locations_on_id"

  create_table "rain_fall_records", force: :cascade do |t|
    t.float    "precip_amount"
    t.integer  "weather_data_recording_id"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  add_index "rain_fall_records", ["weather_data_recording_id"], name: "index_rain_fall_records_on_weather_data_recording_id"

  create_table "temperature_records", force: :cascade do |t|
    t.float    "cel_degree"
    t.integer  "weather_data_recording_id"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  add_index "temperature_records", ["weather_data_recording_id"], name: "index_temperature_records_on_weather_data_recording_id"

  create_table "weather_data_recordings", force: :cascade do |t|
    t.string   "condition"
    t.string   "location_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "weather_data_recordings", ["location_id"], name: "index_weather_data_recordings_on_location_id"

  create_table "wind_records", force: :cascade do |t|
    t.float    "win_dir"
    t.float    "win_speed"
    t.integer  "weather_data_recording_id"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  add_index "wind_records", ["weather_data_recording_id"], name: "index_wind_records_on_weather_data_recording_id"

end
