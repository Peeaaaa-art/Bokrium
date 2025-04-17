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

ActiveRecord::Schema[8.0].define(version: 2025_04_17_071359) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "book_tags", force: :cascade do |t|
    t.bigint "book_id", null: false
    t.bigint "tag_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["book_id"], name: "index_book_tags_on_book_id"
    t.index ["tag_id"], name: "index_book_tags_on_tag_id"
  end

  create_table "books", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "title"
    t.string "isbn"
    t.string "publisher"
    t.integer "page"
    t.string "book_cover"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_books_on_user_id"
  end

  create_table "comments", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "memo_id", null: false
    t.text "body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["memo_id"], name: "index_comments_on_memo_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "images", force: :cascade do |t|
    t.bigint "memo_id", null: false
    t.string "image_path"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["memo_id"], name: "index_images_on_memo_id"
  end

  create_table "like_memos", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "memo_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["memo_id"], name: "index_like_memos_on_memo_id"
    t.index ["user_id"], name: "index_like_memos_on_user_id"
  end

  create_table "line_notification_statuses", force: :cascade do |t|
    t.bigint "line_user_id", null: false
    t.bigint "line_notification_id", null: false
    t.string "status"
    t.datetime "sent_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["line_notification_id"], name: "index_line_notification_statuses_on_line_notification_id"
    t.index ["line_user_id"], name: "index_line_notification_statuses_on_line_user_id"
  end

  create_table "line_notifications", force: :cascade do |t|
    t.bigint "memo_id", null: false
    t.string "title"
    t.text "content"
    t.datetime "schedule_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["memo_id"], name: "index_line_notifications_on_memo_id"
  end

  create_table "line_users", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "line_id"
    t.string "line_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_line_users_on_user_id"
  end

  create_table "memos", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "book_id", null: false
    t.jsonb "content"
    t.tsvector "text_index"
    t.boolean "published"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["book_id"], name: "index_memos_on_book_id"
    t.index ["user_id"], name: "index_memos_on_user_id"
  end

  create_table "search_terms", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "term"
    t.integer "score"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_search_terms_on_user_id"
  end

  create_table "tags", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email", default: "", null: false
    t.text "introduction"
    t.string "avatar"
    t.string "encrypted_password", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "book_tags", "books"
  add_foreign_key "book_tags", "tags"
  add_foreign_key "books", "users"
  add_foreign_key "comments", "memos"
  add_foreign_key "comments", "users"
  add_foreign_key "images", "memos"
  add_foreign_key "like_memos", "memos"
  add_foreign_key "like_memos", "users"
  add_foreign_key "line_notification_statuses", "line_notifications"
  add_foreign_key "line_notification_statuses", "line_users"
  add_foreign_key "line_notifications", "memos"
  add_foreign_key "line_users", "users"
  add_foreign_key "memos", "books"
  add_foreign_key "memos", "users"
  add_foreign_key "search_terms", "users"
end
