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

ActiveRecord::Schema.define(version: 2019_01_17_210728) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "answers", force: :cascade do |t|
    t.string "short_answer"
    t.text "notes"
    t.bigint "question_id"
    t.bigint "knock_id"
    t.index ["knock_id"], name: "index_answers_on_knock_id"
    t.index ["question_id"], name: "index_answers_on_question_id"
  end

  create_table "canvassers", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "doors", force: :cascade do |t|
    t.string "address"
    t.string "zip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "knocks", force: :cascade do |t|
    t.string "resident_name"
    t.string "neighborhood"
    t.string "followup"
    t.string "language"
    t.string "race"
    t.string "gender"
    t.string "contact"
    t.string "when"
    t.bigint "door_id"
    t.bigint "canvasser_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["canvasser_id"], name: "index_knocks_on_canvasser_id"
    t.index ["door_id"], name: "index_knocks_on_door_id"
  end

  create_table "questions", force: :cascade do |t|
    t.string "description"
    t.text "main_question_text"
    t.text "notes_question_text"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "answers", "knocks"
  add_foreign_key "answers", "questions"
  add_foreign_key "knocks", "canvassers"
  add_foreign_key "knocks", "doors"
end
