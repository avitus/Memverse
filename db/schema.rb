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

ActiveRecord::Schema.define(version: 20170420163138) do

  create_table "american_states", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "abbrev", limit: 20, default: "", null: false
    t.string "name", limit: 50, default: "", null: false
    t.integer "users_count", default: 0
    t.integer "population"
    t.integer "rank"
    t.string "slug"
    t.index ["name"], name: "index_american_states_on_name", unique: true
    t.index ["slug"], name: "index_american_states_on_slug"
    t.index ["users_count"], name: "index_american_states_on_users_count"
  end

  create_table "badges", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name"
    t.text "description"
    t.string "color"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "badges_users", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "badge_id"
    t.integer "user_id"
  end

  create_table "bloggity_blog_assets", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "blog_post_id"
    t.integer "parent_id"
    t.string "content_type"
    t.string "filename"
    t.string "thumbnail"
    t.integer "size"
    t.integer "width"
    t.integer "height"
  end

  create_table "bloggity_blog_categories", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name"
    t.integer "parent_id"
    t.integer "blog_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["blog_id"], name: "index_blog_categories_on_blog_id"
    t.index ["parent_id"], name: "index_blog_categories_on_parent_id"
  end

  create_table "bloggity_blog_comments", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "user_id"
    t.integer "blog_post_id"
    t.text "comment"
    t.boolean "approved"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["blog_post_id"], name: "index_blog_comments_on_blog_post_id"
  end

  create_table "bloggity_blog_posts", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "title"
    t.text "body"
    t.string "tag_string"
    t.integer "posted_by_id"
    t.boolean "is_complete"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "url_identifier"
    t.boolean "comments_closed"
    t.integer "category_id"
    t.integer "blog_id", default: 1
    t.boolean "fck_created"
    t.boolean "tweeted", default: false
    t.index ["blog_id"], name: "index_blog_posts_on_blog_id"
    t.index ["category_id"], name: "index_blog_posts_on_category_id"
    t.index ["url_identifier"], name: "index_blog_posts_on_url_identifier"
  end

  create_table "bloggity_blog_tags", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name"
    t.integer "blog_post_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["blog_post_id"], name: "index_blog_tags_on_blog_post_id"
  end

  create_table "bloggity_blogs", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "title"
    t.string "subtitle"
    t.string "url_identifier"
    t.string "stylesheet"
    t.string "feedburner_url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["url_identifier"], name: "index_blogs_on_url_identifier"
  end

  create_table "churches", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name", null: false
    t.text "description"
    t.integer "country_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "users_count", default: 0
    t.integer "rank"
    t.index ["name"], name: "index_churches_on_name", unique: true
    t.index ["users_count"], name: "index_churches_on_users_count"
  end

  create_table "ckeditor_assets", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "data_file_name", null: false
    t.string "data_content_type"
    t.integer "data_file_size"
    t.integer "assetable_id"
    t.string "assetable_type", limit: 30
    t.string "type", limit: 30
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["assetable_type", "assetable_id"], name: "idx_ckeditor_assetable"
    t.index ["assetable_type", "type", "assetable_id"], name: "idx_ckeditor_assetable_type"
  end

  create_table "countries", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "iso", limit: 2, null: false
    t.string "name", limit: 80, null: false
    t.string "printable_name", limit: 80, null: false
    t.string "iso3", limit: 3
    t.integer "numcode", limit: 2
    t.integer "users_count", default: 0
    t.integer "rank"
    t.string "slug"
    t.index ["printable_name"], name: "index_countries_on_printable_name", unique: true
    t.index ["slug"], name: "index_countries_on_slug"
    t.index ["users_count"], name: "index_countries_on_users_count"
  end

  create_table "daily_stats", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.date "entry_date", null: false
    t.integer "users"
    t.integer "users_active_in_month"
    t.integer "verses"
    t.integer "memverses"
    t.integer "memverses_learning"
    t.integer "memverses_memorized"
    t.integer "memverses_learning_active_in_month"
    t.integer "memverses_memorized_not_overdue"
    t.string "segment", default: "Global"
    t.index ["segment"], name: "index_daily_stats_on_segment"
  end

  create_table "devotions", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name"
    t.string "ref"
    t.text "thought"
    t.integer "month"
    t.integer "day"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["day"], name: "index_devotions_on_day"
    t.index ["month"], name: "index_devotions_on_month"
    t.index ["name"], name: "index_devotions_on_name"
  end

  create_table "final_verses", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "book", null: false
    t.integer "chapter", null: false
    t.integer "last_verse", null: false
    t.index ["book", "chapter"], name: "index_final_verses_on_book_and_chapter"
  end

  create_table "forem_categories", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "slug"
    t.integer "position", default: 0
    t.index ["slug"], name: "index_forem_categories_on_slug", unique: true
  end

  create_table "forem_forums", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name"
    t.text "description"
    t.integer "category_id"
    t.integer "views_count", default: 0
    t.string "slug"
    t.integer "position", default: 0
    t.index ["slug"], name: "index_forem_forums_on_slug", unique: true
  end

  create_table "forem_groups", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name"
    t.index ["name"], name: "index_forem_groups_on_name"
  end

  create_table "forem_memberships", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "group_id"
    t.integer "member_id"
    t.index ["group_id"], name: "index_forem_memberships_on_group_id"
  end

  create_table "forem_moderator_groups", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "forum_id"
    t.integer "group_id"
    t.index ["forum_id"], name: "index_forem_moderator_groups_on_forum_id"
  end

  create_table "forem_posts", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "topic_id"
    t.text "text"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "reply_to_id"
    t.string "state", default: "pending_review"
    t.boolean "notified", default: false
    t.index ["reply_to_id"], name: "index_forem_posts_on_reply_to_id"
    t.index ["state"], name: "index_forem_posts_on_state"
    t.index ["topic_id"], name: "index_forem_posts_on_topic_id"
    t.index ["user_id"], name: "index_forem_posts_on_user_id"
  end

  create_table "forem_subscriptions", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "subscriber_id"
    t.integer "topic_id"
  end

  create_table "forem_topics", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "forum_id"
    t.integer "user_id"
    t.string "subject"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "locked", default: false, null: false
    t.boolean "pinned", default: false
    t.boolean "hidden", default: false
    t.datetime "last_post_at"
    t.string "state", default: "pending_review"
    t.integer "views_count", default: 0
    t.string "slug"
    t.index ["forum_id"], name: "index_forem_topics_on_forum_id"
    t.index ["slug"], name: "index_forem_topics_on_slug", unique: true
    t.index ["state"], name: "index_forem_topics_on_state"
    t.index ["user_id"], name: "index_forem_topics_on_user_id"
  end

  create_table "forem_views", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "user_id"
    t.integer "viewable_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "count", default: 0
    t.string "viewable_type"
    t.datetime "current_viewed_at"
    t.datetime "past_viewed_at"
    t.index ["updated_at"], name: "index_forem_views_on_updated_at"
    t.index ["user_id"], name: "index_forem_views_on_user_id"
    t.index ["viewable_id"], name: "index_forem_views_on_topic_id"
  end

  create_table "friendly_id_slugs", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "slug", limit: 191, null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.string "scope", limit: 191
    t.datetime "created_at"
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id"
    t.index ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type"
  end

  create_table "groups", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name", null: false
    t.text "description"
    t.integer "rank"
    t.integer "users_count", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "leader_id"
  end

  create_table "memverses", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "user_id", null: false
    t.integer "verse_id", null: false
    t.decimal "efactor", precision: 5, scale: 1, default: "0.0"
    t.integer "test_interval", default: 1
    t.integer "rep_n", default: 1
    t.date "next_test"
    t.date "last_tested"
    t.string "status"
    t.integer "attempts", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "first_verse"
    t.integer "prev_verse"
    t.integer "next_verse"
    t.integer "ref_interval", default: 1
    t.date "next_ref_test"
    t.integer "uberverse_id"
    t.integer "passage_id"
    t.integer "subsection"
    t.index ["passage_id"], name: "index_memverses_on_passage_id"
    t.index ["status"], name: "index_memverses_on_status"
    t.index ["user_id", "verse_id"], name: "index_memverses_on_user_id_and_verse_id", unique: true
    t.index ["user_id"], name: "index_memverses_on_user_id"
    t.index ["verse_id"], name: "index_memverses_on_verse_id"
  end

  create_table "oauth_access_grants", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "resource_owner_id", null: false
    t.integer "application_id", null: false
    t.string "token", null: false
    t.integer "expires_in", null: false
    t.string "redirect_uri", limit: 2048, null: false
    t.datetime "created_at", null: false
    t.datetime "revoked_at"
    t.string "scopes"
    t.index ["token"], name: "index_oauth_access_grants_on_token", unique: true
  end

  create_table "oauth_access_tokens", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "resource_owner_id"
    t.integer "application_id", null: false
    t.string "token", null: false
    t.string "refresh_token"
    t.integer "expires_in"
    t.datetime "revoked_at"
    t.datetime "created_at", null: false
    t.string "scopes"
    t.index ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true
    t.index ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_tokens_on_token", unique: true
  end

  create_table "oauth_applications", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name", null: false
    t.string "uid", null: false
    t.string "secret", null: false
    t.string "redirect_uri", limit: 2048, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "scopes", default: "", null: false
    t.index ["uid"], name: "index_oauth_applications_on_uid", unique: true
  end

  create_table "open_id_authentication_associations", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "issued"
    t.integer "lifetime"
    t.string "handle"
    t.string "assoc_type"
    t.binary "server_url"
    t.binary "secret"
  end

  create_table "open_id_authentication_nonces", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "timestamp", null: false
    t.string "server_url"
    t.string "salt", null: false
  end

  create_table "passages", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "user_id", null: false
    t.integer "length", default: 1, null: false
    t.string "reference", limit: 50
    t.string "translation", limit: 10, null: false
    t.string "book", limit: 40, null: false
    t.integer "chapter", null: false
    t.integer "first_verse", null: false
    t.integer "last_verse", null: false
    t.boolean "complete_chapter", default: false
    t.boolean "synched", default: false
    t.decimal "efactor", precision: 4, scale: 1, default: "2.0"
    t.integer "test_interval", default: 1
    t.integer "rep_n", default: 1
    t.date "next_test"
    t.date "last_tested"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "book_index"
    t.index ["book_index"], name: "index_passages_on_book_index"
    t.index ["user_id"], name: "index_passages_on_user_id"
  end

  create_table "passwords", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "user_id"
    t.string "reset_code"
    t.datetime "expiration_date"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "pastors", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["name"], name: "index_pastors_on_name"
  end

  create_table "popverses", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "pop_ref", null: false
    t.integer "num_users", null: false
    t.string "book", null: false
    t.string "chapter", null: false
    t.string "versenum", null: false
    t.integer "niv"
    t.integer "esv"
    t.integer "nas"
    t.integer "nkj"
    t.integer "kjv"
    t.integer "rsv"
    t.string "niv_text", limit: 300
    t.string "esv_text", limit: 300
    t.string "nas_text", limit: 300
    t.string "nkj_text", limit: 300
    t.string "kjv_text", limit: 300
    t.string "rsv_text", limit: 300
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "progress_reports", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "user_id", null: false
    t.date "entry_date"
    t.integer "learning"
    t.integer "memorized"
    t.integer "time_allocation"
    t.integer "consistency"
    t.integer "reviewed"
    t.boolean "session_complete"
    t.index ["user_id"], name: "index_progress_reports_on_user_id"
  end

  create_table "quests", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "level"
    t.string "task"
    t.text "description"
    t.string "objective"
    t.string "qualifier"
    t.integer "quantity"
    t.string "url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "badge_id"
    t.index ["level"], name: "index_quests_on_level"
    t.index ["objective"], name: "index_quests_on_objective"
    t.index ["qualifier"], name: "index_quests_on_qualifier"
  end

  create_table "quests_users", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "quest_id"
    t.integer "user_id"
  end

  create_table "quiz_questions", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "quiz_id", null: false
    t.integer "question_no"
    t.string "question_type"
    t.string "passage"
    t.text "mc_question"
    t.string "mc_option_a"
    t.string "mc_option_b"
    t.string "mc_option_c"
    t.string "mc_option_d"
    t.string "mc_answer"
    t.integer "times_answered", default: 0
    t.decimal "perc_correct", precision: 10, default: "50"
    t.string "mcq_category"
    t.date "last_asked", default: "2012-10-22"
    t.integer "supporting_ref"
    t.integer "submitted_by"
    t.string "approval_status", default: "Pending"
    t.string "rejection_code"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["approval_status"], name: "index_quiz_questions_on_approval_status"
  end

  create_table "quizzes", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "user_id", null: false
    t.string "name"
    t.text "description"
    t.integer "quiz_questions_count"
    t.datetime "start_time"
    t.integer "quiz_length"
  end

  create_table "rails_admin_histories", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.text "message"
    t.string "username"
    t.integer "item"
    t.string "table"
    t.integer "month", limit: 2
    t.bigint "year"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["item", "table", "month", "year"], name: "index_rails_admin_histories"
  end

  create_table "roles", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name"
  end

  create_table "roles_users", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "role_id"
    t.integer "user_id"
  end

  create_table "rpush_apps", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name", null: false
    t.string "environment"
    t.text "certificate"
    t.string "password"
    t.integer "connections", default: 1, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "type", null: false
    t.string "auth_key"
    t.string "client_id"
    t.string "client_secret"
    t.string "access_token"
    t.datetime "access_token_expiration"
  end

  create_table "rpush_feedback", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "device_token", limit: 64, null: false
    t.datetime "failed_at", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "app_id"
    t.index ["device_token"], name: "index_rpush_feedback_on_device_token"
  end

  create_table "rpush_notifications", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "badge"
    t.string "device_token", limit: 64
    t.string "sound", default: "default"
    t.string "alert"
    t.text "data"
    t.integer "expiry", default: 86400
    t.boolean "delivered", default: false, null: false
    t.datetime "delivered_at"
    t.boolean "failed", default: false, null: false
    t.datetime "failed_at"
    t.integer "error_code"
    t.text "error_description"
    t.datetime "deliver_after"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "alert_is_json", default: false
    t.string "type", null: false
    t.string "collapse_key"
    t.boolean "delay_while_idle", default: false, null: false
    t.text "registration_ids", limit: 16777215
    t.integer "app_id", null: false
    t.integer "retries", default: 0
    t.string "uri"
    t.datetime "fail_after"
    t.boolean "processing", default: false, null: false
    t.integer "priority"
    t.text "url_args"
    t.string "category"
    t.boolean "content_available", default: false
    t.index ["app_id", "delivered", "failed", "deliver_after"], name: "index_rapns_notifications_multi"
    t.index ["delivered", "failed"], name: "index_rpush_notifications_multi"
  end

  create_table "sermons", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "title"
    t.text "summary"
    t.integer "church_id"
    t.integer "pastor_id"
    t.integer "user_id"
    t.integer "uberverse_id"
    t.string "mp3_file_name"
    t.string "mp3_content_type"
    t.integer "mp3_file_size"
    t.datetime "mp3_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["church_id"], name: "index_sermons_on_church_id"
    t.index ["pastor_id"], name: "index_sermons_on_pastor_id"
    t.index ["title"], name: "index_sermons_on_title"
    t.index ["uberverse_id"], name: "index_sermons_on_uberverse_id"
    t.index ["user_id"], name: "index_sermons_on_user_id"
  end

  create_table "sessions", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "session_id", null: false
    t.text "data"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["session_id"], name: "index_sessions_on_session_id"
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "taggings", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "tag_id"
    t.integer "taggable_id"
    t.integer "tagger_id"
    t.string "tagger_type"
    t.string "taggable_type"
    t.string "context"
    t.datetime "created_at"
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
    t.index ["taggable_id", "taggable_type", "context"], name: "index_taggings_on_taggable_id_and_taggable_type_and_context"
  end

  create_table "tags", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name"
    t.integer "taggings_count", default: 0
  end

  create_table "thredded_categories", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "messageboard_id", null: false
    t.string "name", limit: 191, null: false
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "slug", limit: 191, null: false
    t.index ["messageboard_id", "slug"], name: "index_thredded_categories_on_messageboard_id_and_slug", unique: true
    t.index ["messageboard_id"], name: "index_thredded_categories_on_messageboard_id"
    t.index ["name"], name: "thredded_categories_name_ci"
  end

  create_table "thredded_messageboard_groups", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "position", null: false
    t.index ["name"], name: "index_thredded_messageboard_group_on_name", unique: true
  end

  create_table "thredded_messageboard_notifications_for_followed_topics", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "user_id", null: false
    t.integer "messageboard_id", null: false
    t.string "notifier_key", limit: 90, null: false
    t.boolean "enabled", default: true, null: false
    t.index ["user_id", "messageboard_id", "notifier_key"], name: "thredded_messageboard_notifications_for_followed_topics_unique", unique: true
  end

  create_table "thredded_messageboard_users", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "thredded_user_detail_id", null: false
    t.integer "thredded_messageboard_id", null: false
    t.datetime "last_seen_at", null: false
    t.index ["thredded_messageboard_id", "last_seen_at"], name: "index_thredded_messageboard_users_for_recently_active"
    t.index ["thredded_messageboard_id", "thredded_user_detail_id"], name: "index_thredded_messageboard_users_primary"
    t.index ["thredded_user_detail_id"], name: "fk_rails_06e42c62f5"
  end

  create_table "thredded_messageboards", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name", limit: 191, null: false
    t.string "slug", limit: 191
    t.text "description"
    t.integer "topics_count", default: 0
    t.integer "posts_count", default: 0
    t.integer "last_topic_id"
    t.integer "messageboard_group_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "position", null: false
    t.index ["messageboard_group_id"], name: "index_thredded_messageboards_on_messageboard_group_id"
    t.index ["slug"], name: "index_thredded_messageboards_on_slug"
  end

  create_table "thredded_notifications_for_followed_topics", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "user_id", null: false
    t.string "notifier_key", limit: 90, null: false
    t.boolean "enabled", default: true, null: false
    t.index ["user_id", "notifier_key"], name: "thredded_notifications_for_followed_topics_unique", unique: true
  end

  create_table "thredded_notifications_for_private_topics", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "user_id", null: false
    t.string "notifier_key", limit: 90, null: false
    t.boolean "enabled", default: true, null: false
    t.index ["user_id", "notifier_key"], name: "thredded_notifications_for_private_topics_unique", unique: true
  end

  create_table "thredded_post_moderation_records", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "post_id"
    t.integer "messageboard_id"
    t.text "post_content"
    t.integer "post_user_id"
    t.text "post_user_name"
    t.integer "moderator_id"
    t.integer "moderation_state", null: false
    t.integer "previous_moderation_state", null: false
    t.datetime "created_at", null: false
    t.index ["messageboard_id", "created_at"], name: "index_thredded_moderation_records_for_display"
  end

  create_table "thredded_posts", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "user_id"
    t.text "content"
    t.string "ip"
    t.string "source", default: "web"
    t.integer "postable_id", null: false
    t.integer "messageboard_id", null: false
    t.integer "moderation_state", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "thredded_private_posts", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "user_id"
    t.text "content"
    t.integer "postable_id", null: false
    t.string "ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "thredded_private_topics", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "user_id"
    t.integer "last_user_id"
    t.string "title", null: false
    t.string "slug", limit: 191, null: false
    t.integer "posts_count", default: 0
    t.string "hash_id", limit: 191, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "last_post_at"
    t.index ["hash_id"], name: "index_thredded_private_topics_on_hash_id"
    t.index ["slug"], name: "index_thredded_private_topics_on_slug"
  end

  create_table "thredded_private_users", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "private_topic_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["private_topic_id"], name: "index_thredded_private_users_on_private_topic_id"
    t.index ["user_id"], name: "index_thredded_private_users_on_user_id"
  end

  create_table "thredded_topic_categories", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "topic_id", null: false
    t.integer "category_id", null: false
    t.index ["category_id"], name: "index_thredded_topic_categories_on_category_id"
    t.index ["topic_id"], name: "index_thredded_topic_categories_on_topic_id"
  end

  create_table "thredded_topics", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "user_id"
    t.integer "last_user_id"
    t.string "title", null: false
    t.string "slug", limit: 191, null: false
    t.integer "messageboard_id", null: false
    t.integer "posts_count", default: 0, null: false
    t.boolean "sticky", default: false, null: false
    t.boolean "locked", default: false, null: false
    t.string "hash_id", limit: 191, null: false
    t.string "type", limit: 191
    t.integer "moderation_state", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "last_post_at"
    t.index ["hash_id"], name: "index_thredded_topics_on_hash_id"
    t.index ["messageboard_id"], name: "index_thredded_topics_on_messageboard_id"
    t.index ["moderation_state", "sticky", "updated_at"], name: "index_thredded_topics_for_display"
    t.index ["slug"], name: "index_thredded_topics_on_slug", unique: true
    t.index ["user_id"], name: "index_thredded_topics_on_user_id"
  end

  create_table "thredded_user_details", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "user_id", null: false
    t.datetime "latest_activity_at"
    t.integer "posts_count", default: 0
    t.integer "topics_count", default: 0
    t.datetime "last_seen_at"
    t.integer "moderation_state", default: 0, null: false
    t.datetime "moderation_state_changed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["latest_activity_at"], name: "index_thredded_user_details_on_latest_activity_at"
    t.index ["moderation_state", "moderation_state_changed_at"], name: "index_thredded_user_details_for_moderations"
    t.index ["user_id"], name: "index_thredded_user_details_on_user_id"
  end

  create_table "thredded_user_messageboard_preferences", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "user_id", null: false
    t.integer "messageboard_id", null: false
    t.boolean "follow_topics_on_mention", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "auto_follow_topics", default: false, null: false
    t.index ["user_id", "messageboard_id"], name: "thredded_user_messageboard_preferences_user_id_messageboard_id", unique: true
  end

  create_table "thredded_user_post_notifications", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "user_id", null: false
    t.integer "post_id", null: false
    t.datetime "notified_at", null: false
    t.index ["post_id"], name: "index_thredded_user_post_notifications_on_post_id"
    t.index ["user_id", "post_id"], name: "index_thredded_user_post_notifications_on_user_id_and_post_id", unique: true
  end

  create_table "thredded_user_preferences", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "user_id", null: false
    t.boolean "follow_topics_on_mention", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "auto_follow_topics", default: false, null: false
    t.index ["user_id"], name: "index_thredded_user_preferences_on_user_id"
  end

  create_table "thredded_user_private_topic_read_states", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "user_id", null: false
    t.integer "postable_id", null: false
    t.integer "page", default: 1, null: false
    t.datetime "read_at", null: false
    t.index ["user_id", "postable_id"], name: "thredded_user_private_topic_read_states_user_postable", unique: true
  end

  create_table "thredded_user_topic_follows", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "user_id", null: false
    t.integer "topic_id", null: false
    t.datetime "created_at", null: false
    t.integer "reason", limit: 1
    t.index ["user_id", "topic_id"], name: "thredded_user_topic_follows_user_topic", unique: true
  end

  create_table "thredded_user_topic_read_states", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "user_id", null: false
    t.integer "postable_id", null: false
    t.integer "page", default: 1, null: false
    t.datetime "read_at", null: false
    t.index ["user_id", "postable_id"], name: "thredded_user_topic_read_states_user_postable", unique: true
  end

  create_table "tweets", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "importance", default: 5
    t.integer "user_id"
    t.integer "church_id"
    t.integer "american_state_id"
    t.integer "country_id"
    t.string "news"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "group_id"
    t.index ["american_state_id"], name: "index_tweets_on_american_state_id"
    t.index ["church_id"], name: "index_tweets_on_church_id"
    t.index ["country_id"], name: "index_tweets_on_country_id"
    t.index ["importance"], name: "index_tweets_on_importance"
    t.index ["user_id"], name: "index_tweets_on_user_id"
  end

  create_table "uberverses", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "book", null: false
    t.integer "chapter", null: false
    t.integer "versenum", null: false
    t.integer "book_index"
    t.integer "subsection_end"
    t.index ["book"], name: "index_uberverses_on_book"
    t.index ["book_index"], name: "index_uberverses_on_book_index"
    t.index ["chapter"], name: "index_uberverses_on_chapter"
    t.index ["versenum"], name: "index_uberverses_on_versenum"
  end

  create_table "uberverses_sermons", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "uberverse_id"
    t.integer "sermon_id"
    t.boolean "primary_verse", default: false
  end

  create_table "users", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "login", limit: 40
    t.string "identity_url"
    t.string "name", limit: 100, default: ""
    t.string "email", limit: 100
    t.string "encrypted_password", limit: 128, default: "", null: false
    t.string "password_salt", default: "", null: false
    t.string "remember_token", limit: 40
    t.string "confirmation_token"
    t.datetime "remember_token_expires_at"
    t.datetime "confirmed_at"
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.date "last_reminder"
    t.string "reminder_freq", default: "weekly"
    t.boolean "newsletters", default: true
    t.integer "church_id"
    t.integer "country_id"
    t.string "language", default: "English"
    t.integer "time_allocation", default: 5
    t.integer "memorized", default: 0
    t.integer "learning", default: 0
    t.date "last_activity_date"
    t.boolean "show_echo", default: true
    t.integer "max_interval", default: 366
    t.string "mnemonic_use", default: "Learning"
    t.integer "american_state_id"
    t.integer "accuracy", default: 10
    t.boolean "all_refs", default: true
    t.integer "rank"
    t.integer "ref_grade", default: 10
    t.string "gender"
    t.string "translation"
    t.integer "level", default: 0, null: false
    t.integer "referred_by"
    t.boolean "show_email", default: false
    t.boolean "auto_work_load", default: true
    t.datetime "confirmation_sent_at"
    t.string "reset_password_token"
    t.datetime "remember_created_at"
    t.boolean "admin", default: false
    t.integer "group_id"
    t.datetime "reset_password_sent_at"
    t.boolean "thredded_admin", default: false
    t.string "forem_state", default: "pending_review"
    t.boolean "forem_auto_subscribe", default: false
    t.string "unconfirmed_email"
    t.string "provider"
    t.string "uid"
    t.boolean "sync_subsections", default: false
    t.boolean "quiz_alert", default: false
    t.string "device_token"
    t.string "device_type"
    t.string "time_zone", default: "UTC"
    t.index ["american_state_id"], name: "index_users_on_american_state_id"
    t.index ["church_id"], name: "index_users_on_church_id"
    t.index ["country_id"], name: "index_users_on_country_id"
    t.index ["last_activity_date"], name: "index_users_on_last_activity_date"
    t.index ["login"], name: "index_users_on_login", unique: true
    t.index ["quiz_alert"], name: "index_users_on_quiz_alert"
    t.index ["referred_by"], name: "index_users_on_referred_by"
  end

  create_table "verses", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "translation", null: false
    t.integer "book_index", null: false
    t.string "book", null: false
    t.integer "chapter", null: false
    t.integer "versenum", null: false
    t.text "text"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "verified", default: false, null: false
    t.boolean "error_flag", default: false, null: false
    t.integer "uberverse_id"
    t.string "checked_by"
    t.integer "memverses_count", default: 0
    t.decimal "difficulty", precision: 5, scale: 2
    t.decimal "popularity", precision: 5, scale: 2
    t.index ["book"], name: "index_verses_on_book"
    t.index ["book_index"], name: "index_verses_on_book_index"
    t.index ["chapter"], name: "index_verses_on_chapter"
    t.index ["error_flag"], name: "index_verses_on_error_flag"
    t.index ["translation", "book", "chapter", "versenum"], name: "index_verses_on_translation_and_book_and_chapter_and_versenum", unique: true
    t.index ["translation"], name: "index_verses_on_translation"
    t.index ["verified"], name: "index_verses_on_verified"
    t.index ["versenum"], name: "index_verses_on_versenum"
  end

  add_foreign_key "thredded_messageboard_users", "thredded_messageboards", on_delete: :cascade
  add_foreign_key "thredded_messageboard_users", "thredded_user_details", on_delete: :cascade
  add_foreign_key "thredded_user_post_notifications", "thredded_posts", column: "post_id", on_delete: :cascade
  add_foreign_key "thredded_user_post_notifications", "users", on_delete: :cascade
end
