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

ActiveRecord::Schema.define(version: 2021_03_08_044214) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "mock_groups", force: :cascade do |t|
    t.text "scim_uid"
    t.text "display_name"
    t.bigint "parent_id"
    t.index ["parent_id"], name: "index_mock_groups_on_parent_id"
  end

  create_table "mock_groups_users", id: false, force: :cascade do |t|
    t.bigint "mock_group_id", null: false
    t.bigint "mock_user_id", null: false
    t.index ["mock_group_id", "mock_user_id"], name: "index_mock_groups_users_on_mock_group_id_and_mock_user_id"
    t.index ["mock_user_id", "mock_group_id"], name: "index_mock_groups_users_on_mock_user_id_and_mock_group_id"
  end

  create_table "mock_users", force: :cascade do |t|
    t.text "scim_uid"
    t.text "username"
    t.text "first_name"
    t.text "last_name"
    t.text "work_email_address"
    t.text "home_email_address"
    t.text "work_phone_number"
  end

end
