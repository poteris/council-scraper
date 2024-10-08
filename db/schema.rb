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

ActiveRecord::Schema[7.0].define(version: 2024_09_10_134336) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

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

  create_table "committees", force: :cascade do |t|
    t.bigint "council_id", null: false
    t.text "name"
    t.text "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "modern_gov_id"
    t.index ["council_id"], name: "index_committees_on_council_id"
  end

  create_table "council_syncs", force: :cascade do |t|
    t.bigint "council_id", null: false
    t.date "week", null: false
    t.string "status", default: "waiting", null: false
    t.datetime "last_synced_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "kind", default: "scrape", null: false
    t.index ["council_id"], name: "index_council_syncs_on_council_id"
  end

  create_table "councils", force: :cascade do |t|
    t.text "name"
    t.text "external_id"
    t.text "base_scrape_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "majority_party"
    t.integer "council_type"
  end

  create_table "decision_classifications", force: :cascade do |t|
    t.bigint "decision_id", null: false
    t.text "input"
    t.jsonb "output"
    t.jsonb "classifications"
    t.integer "input_token_count"
    t.integer "output_token_count"
    t.integer "cost"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "model", null: false
    t.index ["decision_id"], name: "index_decision_classifications_on_decision_id"
  end

  create_table "decisions", force: :cascade do |t|
    t.bigint "council_id", null: false
    t.text "url", null: false
    t.text "decision_maker"
    t.text "outcome"
    t.boolean "is_key", default: false, null: false
    t.boolean "is_callable_in", default: false, null: false
    t.text "purpose"
    t.text "content"
    t.date "date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "topline"
    t.index ["council_id"], name: "index_decisions_on_council_id"
  end

  create_table "document_classifications", force: :cascade do |t|
    t.bigint "document_id", null: false
    t.text "input"
    t.jsonb "output"
    t.jsonb "classifications"
    t.integer "input_token_count"
    t.integer "output_token_count"
    t.integer "cost"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "model", null: false
    t.index ["document_id"], name: "index_document_classifications_on_document_id"
  end

  create_table "documents", force: :cascade do |t|
    t.bigint "meeting_id", null: false
    t.text "name"
    t.text "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "text"
    t.text "extract_status", default: "pending", null: false
    t.text "processing_status", default: "waiting", null: false
    t.text "kind", default: "unclassified", null: false
    t.boolean "contains_agenda", default: false, null: false
    t.boolean "contains_attendees", default: false, null: false
    t.boolean "contains_decisions", default: false, null: false
    t.boolean "is_minutes", default: false, null: false
    t.boolean "is_media", default: false, null: false
    t.string "etag"
    t.index ["meeting_id"], name: "index_documents_on_meeting_id"
  end

  create_table "meeting_tags", force: :cascade do |t|
    t.bigint "meeting_id", null: false
    t.bigint "tag_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["meeting_id"], name: "index_meeting_tags_on_meeting_id"
    t.index ["tag_id"], name: "index_meeting_tags_on_tag_id"
  end

  create_table "meetings", force: :cascade do |t|
    t.bigint "council_id", null: false
    t.bigint "committee_id"
    t.text "name"
    t.text "url"
    t.text "notes"
    t.datetime "date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "agenda"
    t.text "about"
    t.jsonb "additional_attendees", default: [], null: false
    t.jsonb "decisions", default: [], null: false
    t.text "topline"
    t.string "etag"
    t.index ["committee_id"], name: "index_meetings_on_committee_id"
    t.index ["council_id"], name: "index_meetings_on_council_id"
    t.index ["date"], name: "index_meetings_on_date"
  end

  create_table "people", force: :cascade do |t|
    t.bigint "council_id", null: false
    t.text "name"
    t.text "role"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "modern_gov_id"
    t.integer "ocd_id"
    t.text "party"
    t.boolean "is_councillor", default: false, null: false
    t.index ["council_id"], name: "index_people_on_council_id"
  end

  create_table "person_meetings", force: :cascade do |t|
    t.bigint "meeting_id", null: false
    t.bigint "person_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["meeting_id"], name: "index_person_meetings_on_meeting_id"
    t.index ["person_id"], name: "index_person_meetings_on_person_id"
  end

  create_table "tags", force: :cascade do |t|
    t.text "tag", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "committees", "councils"
  add_foreign_key "council_syncs", "councils"
  add_foreign_key "decision_classifications", "decisions"
  add_foreign_key "decisions", "councils"
  add_foreign_key "document_classifications", "documents"
  add_foreign_key "documents", "meetings"
  add_foreign_key "meeting_tags", "meetings"
  add_foreign_key "meeting_tags", "tags"
  add_foreign_key "meetings", "committees"
  add_foreign_key "meetings", "councils"
  add_foreign_key "people", "councils"
  add_foreign_key "person_meetings", "meetings"
  add_foreign_key "person_meetings", "people"
end
