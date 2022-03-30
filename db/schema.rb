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

ActiveRecord::Schema[6.1].define(version: 2017_01_31_164346) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "uuid-ossp"

  create_table "memberships", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "room_id"
    t.uuid "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "open", default: false
    t.index ["room_id", "user_id"], name: "index_memberships_on_room_id_and_user_id", unique: true
    t.index ["room_id"], name: "index_memberships_on_room_id"
    t.index ["user_id"], name: "index_memberships_on_user_id"
  end

  create_table "message_user_statuses", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "message_id", null: false
    t.uuid "user_id", null: false
    t.boolean "notified", default: false, null: false
    t.boolean "read", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["message_id", "user_id"], name: "idx_message_status_component_key", unique: true
    t.index ["message_id"], name: "index_message_user_statuses_on_message_id"
    t.index ["user_id"], name: "index_message_user_statuses_on_user_id"
  end

  create_table "messages", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "room_id"
    t.uuid "sender_id"
    t.text "content"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "public_id", null: false
    t.serial "sequence_number", null: false
    t.string "device_session_id"
    t.index ["room_id", "public_id"], name: "index_messages_on_room_id_and_public_id", unique: true
    t.index ["room_id"], name: "index_messages_on_room_id"
    t.index ["sender_id"], name: "index_messages_on_sender_id"
    t.index ["sequence_number"], name: "index_messages_on_sequence_number", unique: true
  end

  create_table "platforms", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "user_rsa_public", null: false
    t.text "user_rsa_private", null: false
    t.text "platform_rsa_public", null: false
    t.text "platform_rsa_private", null: false
    t.string "offline_user_message_hook_url"
  end

  create_table "rooms", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.text "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "initiator_id"
    t.uuid "platform_id", null: false
    t.string "public_id", null: false
    t.datetime "last_activity_at", null: false
    t.index ["initiator_id"], name: "index_rooms_on_initiator_id"
    t.index ["last_activity_at"], name: "index_rooms_on_last_activity_at"
    t.index ["platform_id", "public_id"], name: "index_rooms_on_platform_id_and_public_id", unique: true
  end

  create_table "users", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "platform_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "alive_at"
    t.string "status"
    t.string "public_id", null: false
    t.index ["platform_id", "public_id"], name: "index_users_on_platform_id_and_public_id", unique: true
    t.index ["platform_id"], name: "index_users_on_platform_id"
  end

  add_foreign_key "memberships", "rooms", name: "fk_membership_to_rooms"
  add_foreign_key "memberships", "users", name: "fk_membership_to_users"
  add_foreign_key "message_user_statuses", "messages", name: "fk_message_status_to_messages"
  add_foreign_key "message_user_statuses", "users", name: "fk_message_status_to_users"
  add_foreign_key "messages", "rooms", name: "fk_message_to_rooms"
  add_foreign_key "messages", "users", column: "sender_id", name: "fk_message_to_senders"
  add_foreign_key "rooms", "platforms", name: "fk_room_to_platforms"
  add_foreign_key "rooms", "users", column: "initiator_id", name: "fk_room_to_initiator_user"
  add_foreign_key "users", "platforms", name: "fk_user_to_platforms"
end
