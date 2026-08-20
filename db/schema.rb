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

ActiveRecord::Schema[8.1].define(version: 2026_08_20_051141) do
  create_table "books", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "author"
    t.boolean "author_confirmed", default: false, null: false
    t.integer "category_id", null: false
    t.string "collection"
    t.datetime "created_at", null: false
    t.string "language", default: "fr", null: false
    t.date "received_on"
    t.string "shelf_mark"
    t.integer "site_id", null: false
    t.text "summary"
    t.string "title", null: false
    t.integer "total_copies", default: 1, null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_books_on_category_id"
    t.index ["site_id", "title"], name: "index_books_on_site_id_and_title", unique: true
    t.index ["site_id"], name: "index_books_on_site_id"
  end

  create_table "categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_categories_on_slug", unique: true
  end

  create_table "loans", force: :cascade do |t|
    t.integer "book_id", null: false
    t.date "borrowed_on", null: false
    t.datetime "created_at", null: false
    t.date "due_on", null: false
    t.integer "member_id", null: false
    t.integer "renewals_count", default: 0, null: false
    t.date "returned_on"
    t.datetime "updated_at", null: false
    t.index ["book_id", "returned_on"], name: "index_loans_on_book_id_and_returned_on"
    t.index ["book_id"], name: "index_loans_on_book_id"
    t.index ["due_on"], name: "index_loans_on_due_on"
    t.index ["member_id", "returned_on"], name: "index_loans_on_member_id_and_returned_on"
    t.index ["member_id"], name: "index_loans_on_member_id"
  end

  create_table "members", force: :cascade do |t|
    t.string "card_number", null: false
    t.datetime "created_at", null: false
    t.date "expires_on", null: false
    t.string "first_name", null: false
    t.date "joined_on", null: false
    t.string "last_name", null: false
    t.text "notes"
    t.string "phone"
    t.integer "site_id", null: false
    t.boolean "suspended", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["card_number"], name: "index_members_on_card_number", unique: true
    t.index ["expires_on"], name: "index_members_on_expires_on"
    t.index ["last_name"], name: "index_members_on_last_name"
    t.index ["site_id"], name: "index_members_on_site_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.string "value", null: false
    t.index ["key"], name: "index_settings_on_key", unique: true
  end

  create_table "sites", force: :cascade do |t|
    t.boolean "active", default: false, null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_sites_on_code", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "books", "categories"
  add_foreign_key "books", "sites"
  add_foreign_key "loans", "books"
  add_foreign_key "loans", "members"
  add_foreign_key "members", "sites"
  add_foreign_key "sessions", "users"
end
