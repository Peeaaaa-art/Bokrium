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

ActiveRecord::Schema[8.0].define(version: 2025_07_02_043558) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "book_tag_assignments", force: :cascade do |t|
    t.bigint "book_id", null: false
    t.bigint "user_tag_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["book_id"], name: "index_book_tag_assignments_on_book_id"
    t.index ["user_id"], name: "index_book_tag_assignments_on_user_id"
    t.index ["user_tag_id"], name: "index_book_tag_assignments_on_user_tag_id"
  end

  create_table "books", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "title", null: false
    t.string "isbn"
    t.string "publisher"
    t.integer "page"
    t.string "book_cover"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "author"
    t.integer "price"
    t.integer "status", default: 0, null: false
    t.string "affiliate_url"
    t.index ["author"], name: "index_books_on_author"
    t.index ["user_id", "isbn"], name: "index_books_on_user_id_and_isbn_unique_if_isbn", unique: true, where: "(isbn IS NOT NULL)"
    t.index ["user_id"], name: "index_books_on_user_id"
  end

  create_table "donations", force: :cascade do |t|
    t.bigint "user_id"
    t.integer "amount", null: false
    t.string "currency", default: "jpy", null: false
    t.string "stripe_payment_intent_id"
    t.string "stripe_checkout_session_id"
    t.string "status", default: "pending", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "customer_id"
    t.index ["user_id"], name: "index_donations_on_user_id"
  end

  create_table "images", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "book_id", null: false
    t.index ["book_id"], name: "index_images_on_book_id"
  end

  create_table "like_memos", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "memo_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["memo_id"], name: "index_like_memos_on_memo_id"
    t.index ["user_id"], name: "index_like_memos_on_user_id"
  end

  create_table "line_users", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "line_id"
    t.string "line_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "notifications_enabled", default: true, null: false
    t.index ["line_id"], name: "index_line_users_on_line_id", unique: true
    t.index ["user_id"], name: "index_line_users_on_user_id"
  end

  create_table "memos", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "book_id", null: false
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "visibility", default: 0, null: false
    t.string "public_token"
    t.index ["book_id"], name: "index_memos_on_book_id"
    t.index ["content"], name: "index_memos_on_content_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["public_token"], name: "index_memos_on_public_token", unique: true
    t.index ["user_id"], name: "index_memos_on_user_id"
    t.index ["visibility"], name: "index_memos_on_visibility"
  end

  create_table "monthly_supports", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "stripe_customer_id"
    t.string "stripe_subscription_id"
    t.string "subscription_status"
    t.boolean "cancel_at_period_end"
    t.datetime "current_period_end"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_monthly_supports_on_user_id"
  end

  create_table "solid_cache_entries", force: :cascade do |t|
    t.binary "key", null: false
    t.binary "value", null: false
    t.datetime "created_at", null: false
    t.bigint "key_hash", null: false
    t.integer "byte_size", null: false
    t.index ["byte_size"], name: "index_solid_cache_entries_on_byte_size"
    t.index ["key_hash", "byte_size"], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    t.index ["key_hash"], name: "index_solid_cache_entries_on_key_hash", unique: true
  end

  create_table "user_tags", force: :cascade do |t|
    t.string "name"
    t.string "color"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_user_tags_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.string "auth_provider", default: "email", null: false
    t.integer "failed_attempts"
    t.string "unlock_token"
    t.datetime "locked_at"
    t.boolean "email_notification_enabled", default: false, null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "book_tag_assignments", "books"
  add_foreign_key "book_tag_assignments", "user_tags"
  add_foreign_key "book_tag_assignments", "users"
  add_foreign_key "books", "users"
  add_foreign_key "donations", "users"
  add_foreign_key "images", "books"
  add_foreign_key "like_memos", "memos"
  add_foreign_key "like_memos", "users"
  add_foreign_key "memos", "books"
  add_foreign_key "memos", "users"
  add_foreign_key "monthly_supports", "users"
  add_foreign_key "user_tags", "users"
end
