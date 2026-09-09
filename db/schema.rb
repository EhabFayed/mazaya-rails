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

ActiveRecord::Schema[8.0].define(version: 2026_09_10_000002) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

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

  create_table "categories", force: :cascade do |t|
    t.string "slug", null: false
    t.string "name_ar", null: false
    t.string "name_en"
    t.text "desc_ar"
    t.text "desc_en"
    t.text "b2c_ar"
    t.text "b2c_en"
    t.text "b2b_ar"
    t.text "b2b_en"
    t.text "about_ar"
    t.text "about_en"
    t.string "finder_ar"
    t.string "finder_en"
    t.jsonb "spec_labels", default: [], null: false
    t.string "catalog_key"
    t.integer "position", default: 0, null: false
    t.boolean "published", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_categories_on_slug", unique: true
  end

  create_table "clients", force: :cascade do |t|
    t.string "name_ar", null: false
    t.string "name_en"
    t.string "bg", default: "#FFFFFF", null: false
    t.integer "position", default: 0, null: false
    t.boolean "published", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "content_lists", force: :cascade do |t|
    t.string "key", null: false
    t.string "label"
    t.jsonb "items", default: [], null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_content_lists_on_key", unique: true
  end

  create_table "departments", force: :cascade do |t|
    t.string "key", null: false
    t.string "name_ar", null: false
    t.string "name_en"
    t.text "desc_ar"
    t.text "desc_en"
    t.string "phone"
    t.string "email"
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_departments_on_key", unique: true
  end

  create_table "documents", force: :cascade do |t|
    t.string "key", null: false
    t.string "doc_type", default: "catalog", null: false
    t.string "title_ar", null: false
    t.string "title_en"
    t.text "desc_ar"
    t.text "desc_en"
    t.string "cta_ar"
    t.string "cta_en"
    t.boolean "gated", default: true, null: false
    t.string "version"
    t.date "version_date"
    t.integer "position", default: 0, null: false
    t.boolean "published", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_documents_on_key", unique: true
  end

  create_table "leads", force: :cascade do |t|
    t.string "kind", default: "contact", null: false
    t.string "name", null: false
    t.string "phone"
    t.string "email"
    t.string "org_type"
    t.string "interest"
    t.text "message"
    t.string "source"
    t.string "download_key"
    t.jsonb "payload", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status", default: "new", null: false
    t.text "notes"
    t.bigint "assigned_to_id"
    t.datetime "contacted_at"
    t.index ["assigned_to_id"], name: "index_leads_on_assigned_to_id"
    t.index ["created_at"], name: "index_leads_on_created_at"
    t.index ["kind"], name: "index_leads_on_kind"
    t.index ["status"], name: "index_leads_on_status"
  end

  create_table "posts", force: :cascade do |t|
    t.string "slug", null: false
    t.string "post_type", default: "article", null: false
    t.string "topic", default: "news", null: false
    t.string "category_ar"
    t.string "category_en"
    t.string "title_ar", null: false
    t.string "title_en"
    t.text "excerpt_ar"
    t.text "excerpt_en"
    t.text "body_ar"
    t.text "body_en"
    t.date "published_on"
    t.boolean "featured", default: false, null: false
    t.boolean "template", default: false, null: false
    t.boolean "published", default: true, null: false
    t.integer "position", default: 0, null: false
    t.jsonb "points", default: [], null: false
    t.jsonb "checklist", default: [], null: false
    t.jsonb "related_slugs", default: [], null: false
    t.string "related_safety_slug"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_posts_on_slug", unique: true
  end

  create_table "products", force: :cascade do |t|
    t.bigint "category_id", null: false
    t.bigint "subcategory_id"
    t.string "slug", null: false
    t.string "code"
    t.string "name_ar", null: false
    t.string "name_en"
    t.text "summary_ar"
    t.text "summary_en"
    t.string "kind", default: "ready", null: false
    t.boolean "popular", default: false, null: false
    t.boolean "published", default: true, null: false
    t.integer "position", default: 0, null: false
    t.jsonb "features", default: [], null: false
    t.jsonb "applications", default: [], null: false
    t.jsonb "specs", default: [], null: false
    t.jsonb "size_cols", default: [], null: false
    t.jsonb "sizes", default: [], null: false
    t.jsonb "faq", default: [], null: false
    t.string "safety_slug"
    t.jsonb "related_slugs", default: [], null: false
    t.jsonb "image_labels", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_products_on_category_id"
    t.index ["code"], name: "index_products_on_code"
    t.index ["slug"], name: "index_products_on_slug", unique: true
    t.index ["subcategory_id"], name: "index_products_on_subcategory_id"
  end

  create_table "projects", force: :cascade do |t|
    t.string "slug", null: false
    t.string "name_ar", null: false
    t.string "name_en"
    t.string "type_ar"
    t.string "type_en"
    t.boolean "featured", default: false, null: false
    t.boolean "published", default: true, null: false
    t.integer "position", default: 0, null: false
    t.string "product_supplied_ar"
    t.string "product_supplied_en"
    t.string "scope_ar"
    t.string "scope_en"
    t.string "quantity_ar"
    t.string "quantity_en"
    t.string "year"
    t.text "requirements_ar"
    t.text "requirements_en"
    t.text "solution_ar"
    t.text "solution_en"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_projects_on_slug", unique: true
  end

  create_table "projects_solutions", id: false, force: :cascade do |t|
    t.bigint "project_id", null: false
    t.bigint "solution_id", null: false
    t.index ["project_id", "solution_id"], name: "index_projects_solutions_on_project_id_and_solution_id", unique: true
  end

  create_table "safety_articles", force: :cascade do |t|
    t.string "slug", null: false
    t.string "name_ar", null: false
    t.string "name_en"
    t.text "summary_ar"
    t.text "summary_en"
    t.jsonb "points", default: [], null: false
    t.jsonb "checklist", default: [], null: false
    t.jsonb "related_slugs", default: [], null: false
    t.integer "position", default: 0, null: false
    t.boolean "published", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_safety_articles_on_slug", unique: true
  end

  create_table "settings", force: :cascade do |t|
    t.string "whatsapp_display"
    t.string "whatsapp_number"
    t.string "phone"
    t.string "email"
    t.text "address_ar"
    t.text "address_en"
    t.text "hours_ar"
    t.text "hours_en"
    t.text "map_embed"
    t.string "rfq_response_ar"
    t.string "rfq_response_en"
    t.text "notify_emails"
    t.integer "founded", default: 1991
    t.integer "content_version", default: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "solutions", force: :cascade do |t|
    t.string "slug", null: false
    t.string "name_ar", null: false
    t.string "name_en"
    t.text "desc_ar"
    t.text "desc_en"
    t.bigint "category_id"
    t.integer "position", default: 0, null: false
    t.boolean "published", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_solutions_on_category_id"
    t.index ["slug"], name: "index_solutions_on_slug", unique: true
  end

  create_table "subcategories", force: :cascade do |t|
    t.bigint "category_id", null: false
    t.string "slug", null: false
    t.string "name_ar", null: false
    t.string "name_en"
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id", "slug"], name: "index_subcategories_on_category_id_and_slug", unique: true
    t.index ["category_id"], name: "index_subcategories_on_category_id"
  end

  create_table "translations", force: :cascade do |t|
    t.string "locale", null: false
    t.string "key", null: false
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["locale", "key"], name: "index_translations_on_locale_and_key", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "role", default: "editor", null: false
    t.boolean "active", default: true, null: false
    t.datetime "last_login_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower((email)::text)", name: "index_users_on_lower_email", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "leads", "users", column: "assigned_to_id"
  add_foreign_key "products", "categories"
  add_foreign_key "products", "subcategories"
  add_foreign_key "solutions", "categories"
  add_foreign_key "subcategories", "categories"
end
