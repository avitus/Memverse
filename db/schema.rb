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

ActiveRecord::Schema.define(version: 20160203213806) do

  create_table "american_states", force: true do |t|
    t.string  "abbrev",      limit: 20, default: "", null: false
    t.string  "name",        limit: 50, default: "", null: false
    t.integer "users_count",            default: 0
    t.integer "population"
    t.integer "rank"
    t.string  "slug"
  end

  add_index "american_states", ["name"], name: "index_american_states_on_name", unique: true, using: :btree
  add_index "american_states", ["slug"], name: "index_american_states_on_slug", using: :btree
  add_index "american_states", ["users_count"], name: "index_american_states_on_users_count", using: :btree

  create_table "badges", force: true do |t|
    t.string   "name"
    t.text     "description"
    t.string   "color"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "badges_users", id: false, force: true do |t|
    t.integer "badge_id"
    t.integer "user_id"
  end

  create_table "bloggity_blog_assets", force: true do |t|
    t.integer "blog_post_id"
    t.integer "parent_id"
    t.string  "content_type"
    t.string  "filename"
    t.string  "thumbnail"
    t.integer "size"
    t.integer "width"
    t.integer "height"
  end

  create_table "bloggity_blog_categories", force: true do |t|
    t.string   "name"
    t.integer  "parent_id"
    t.integer  "blog_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "bloggity_blog_categories", ["blog_id"], name: "index_blog_categories_on_blog_id", using: :btree
  add_index "bloggity_blog_categories", ["parent_id"], name: "index_blog_categories_on_parent_id", using: :btree

  create_table "bloggity_blog_comments", force: true do |t|
    t.integer  "user_id"
    t.integer  "blog_post_id"
    t.text     "comment"
    t.boolean  "approved"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "bloggity_blog_comments", ["blog_post_id"], name: "index_blog_comments_on_blog_post_id", using: :btree

  create_table "bloggity_blog_posts", force: true do |t|
    t.string   "title"
    t.text     "body"
    t.string   "tag_string"
    t.integer  "posted_by_id"
    t.boolean  "is_complete"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "url_identifier"
    t.boolean  "comments_closed"
    t.integer  "category_id"
    t.integer  "blog_id",         default: 1
    t.boolean  "fck_created"
    t.boolean  "tweeted",         default: false
  end

  add_index "bloggity_blog_posts", ["blog_id"], name: "index_blog_posts_on_blog_id", using: :btree
  add_index "bloggity_blog_posts", ["category_id"], name: "index_blog_posts_on_category_id", using: :btree
  add_index "bloggity_blog_posts", ["url_identifier"], name: "index_blog_posts_on_url_identifier", using: :btree

  create_table "bloggity_blog_tags", force: true do |t|
    t.string   "name"
    t.integer  "blog_post_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "bloggity_blog_tags", ["blog_post_id"], name: "index_blog_tags_on_blog_post_id", using: :btree

  create_table "bloggity_blogs", force: true do |t|
    t.string   "title"
    t.string   "subtitle"
    t.string   "url_identifier"
    t.string   "stylesheet"
    t.string   "feedburner_url"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "bloggity_blogs", ["url_identifier"], name: "index_blogs_on_url_identifier", using: :btree

  create_table "churches", force: true do |t|
    t.string   "name",                    null: false
    t.text     "description"
    t.integer  "country_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "users_count", default: 0
    t.integer  "rank"
  end

  add_index "churches", ["name"], name: "index_churches_on_name", unique: true, using: :btree
  add_index "churches", ["users_count"], name: "index_churches_on_users_count", using: :btree

  create_table "ckeditor_assets", force: true do |t|
    t.string   "data_file_name",               null: false
    t.string   "data_content_type"
    t.integer  "data_file_size"
    t.integer  "assetable_id"
    t.string   "assetable_type",    limit: 30
    t.string   "type",              limit: 30
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "ckeditor_assets", ["assetable_type", "assetable_id"], name: "idx_ckeditor_assetable", using: :btree
  add_index "ckeditor_assets", ["assetable_type", "type", "assetable_id"], name: "idx_ckeditor_assetable_type", using: :btree

  create_table "countries", force: true do |t|
    t.string  "iso",            limit: 2,              null: false
    t.string  "name",           limit: 80,             null: false
    t.string  "printable_name", limit: 80,             null: false
    t.string  "iso3",           limit: 3
    t.integer "numcode",        limit: 2
    t.integer "users_count",               default: 0
    t.integer "rank"
    t.string  "slug"
  end

  add_index "countries", ["printable_name"], name: "index_countries_on_printable_name", unique: true, using: :btree
  add_index "countries", ["slug"], name: "index_countries_on_slug", using: :btree
  add_index "countries", ["users_count"], name: "index_countries_on_users_count", using: :btree

  create_table "daily_stats", force: true do |t|
    t.date    "entry_date",                                            null: false
    t.integer "users"
    t.integer "users_active_in_month"
    t.integer "verses"
    t.integer "memverses"
    t.integer "memverses_learning"
    t.integer "memverses_memorized"
    t.integer "memverses_learning_active_in_month"
    t.integer "memverses_memorized_not_overdue"
    t.string  "segment",                            default: "Global"
  end

  add_index "daily_stats", ["segment"], name: "index_daily_stats_on_segment", using: :btree

  create_table "devotions", force: true do |t|
    t.string   "name"
    t.string   "ref"
    t.text     "thought"
    t.integer  "month"
    t.integer  "day"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "devotions", ["day"], name: "index_devotions_on_day", using: :btree
  add_index "devotions", ["month"], name: "index_devotions_on_month", using: :btree
  add_index "devotions", ["name"], name: "index_devotions_on_name", using: :btree

  create_table "final_verses", force: true do |t|
    t.string  "book",       null: false
    t.integer "chapter",    null: false
    t.integer "last_verse", null: false
  end

  add_index "final_verses", ["book", "chapter"], name: "index_final_verses_on_book_and_chapter", using: :btree

  create_table "forem_categories", force: true do |t|
    t.string   "name",                   null: false
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.string   "slug"
    t.integer  "position",   default: 0
  end

  add_index "forem_categories", ["slug"], name: "index_forem_categories_on_slug", unique: true, using: :btree

  create_table "forem_forums", force: true do |t|
    t.string  "name"
    t.text    "description"
    t.integer "category_id"
    t.integer "views_count", default: 0
    t.string  "slug"
    t.integer "position",    default: 0
  end

  add_index "forem_forums", ["slug"], name: "index_forem_forums_on_slug", unique: true, using: :btree

  create_table "forem_groups", force: true do |t|
    t.string "name"
  end

  add_index "forem_groups", ["name"], name: "index_forem_groups_on_name", using: :btree

  create_table "forem_memberships", force: true do |t|
    t.integer "group_id"
    t.integer "member_id"
  end

  add_index "forem_memberships", ["group_id"], name: "index_forem_memberships_on_group_id", using: :btree

  create_table "forem_moderator_groups", force: true do |t|
    t.integer "forum_id"
    t.integer "group_id"
  end

  add_index "forem_moderator_groups", ["forum_id"], name: "index_forem_moderator_groups_on_forum_id", using: :btree

  create_table "forem_posts", force: true do |t|
    t.integer  "topic_id"
    t.text     "text"
    t.integer  "user_id"
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
    t.integer  "reply_to_id"
    t.string   "state",       default: "pending_review"
    t.boolean  "notified",    default: false
  end

  add_index "forem_posts", ["reply_to_id"], name: "index_forem_posts_on_reply_to_id", using: :btree
  add_index "forem_posts", ["state"], name: "index_forem_posts_on_state", using: :btree
  add_index "forem_posts", ["topic_id"], name: "index_forem_posts_on_topic_id", using: :btree
  add_index "forem_posts", ["user_id"], name: "index_forem_posts_on_user_id", using: :btree

  create_table "forem_subscriptions", force: true do |t|
    t.integer "subscriber_id"
    t.integer "topic_id"
  end

  create_table "forem_topics", force: true do |t|
    t.integer  "forum_id"
    t.integer  "user_id"
    t.string   "subject"
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
    t.boolean  "locked",       default: false,            null: false
    t.boolean  "pinned",       default: false
    t.boolean  "hidden",       default: false
    t.datetime "last_post_at"
    t.string   "state",        default: "pending_review"
    t.integer  "views_count",  default: 0
    t.string   "slug"
  end

  add_index "forem_topics", ["forum_id"], name: "index_forem_topics_on_forum_id", using: :btree
  add_index "forem_topics", ["slug"], name: "index_forem_topics_on_slug", unique: true, using: :btree
  add_index "forem_topics", ["state"], name: "index_forem_topics_on_state", using: :btree
  add_index "forem_topics", ["user_id"], name: "index_forem_topics_on_user_id", using: :btree

  create_table "forem_views", force: true do |t|
    t.integer  "user_id"
    t.integer  "viewable_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "count",             default: 0
    t.string   "viewable_type"
    t.datetime "current_viewed_at"
    t.datetime "past_viewed_at"
  end

  add_index "forem_views", ["updated_at"], name: "index_forem_views_on_updated_at", using: :btree
  add_index "forem_views", ["user_id"], name: "index_forem_views_on_user_id", using: :btree
  add_index "forem_views", ["viewable_id"], name: "index_forem_views_on_topic_id", using: :btree

  create_table "groups", force: true do |t|
    t.string   "name",                    null: false
    t.text     "description"
    t.integer  "rank"
    t.integer  "users_count", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "leader_id"
  end

  create_table "memverses", force: true do |t|
    t.integer  "user_id",                                             null: false
    t.integer  "verse_id",                                            null: false
    t.decimal  "efactor",       precision: 5, scale: 1, default: 0.0
    t.integer  "test_interval",                         default: 1
    t.integer  "rep_n",                                 default: 1
    t.date     "next_test"
    t.date     "last_tested"
    t.string   "status"
    t.integer  "attempts",                              default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "first_verse"
    t.integer  "prev_verse"
    t.integer  "next_verse"
    t.integer  "ref_interval",                          default: 1
    t.date     "next_ref_test"
    t.integer  "uberverse_id"
    t.integer  "passage_id"
    t.integer  "subsection"
  end

  add_index "memverses", ["passage_id"], name: "index_memverses_on_passage_id", using: :btree
  add_index "memverses", ["status"], name: "index_memverses_on_status", using: :btree
  add_index "memverses", ["user_id", "verse_id"], name: "index_memverses_on_user_id_and_verse_id", unique: true, using: :btree
  add_index "memverses", ["user_id"], name: "index_memverses_on_user_id", using: :btree
  add_index "memverses", ["verse_id"], name: "index_memverses_on_verse_id", using: :btree

  create_table "oauth_access_grants", force: true do |t|
    t.integer  "resource_owner_id",              null: false
    t.integer  "application_id",                 null: false
    t.string   "token",                          null: false
    t.integer  "expires_in",                     null: false
    t.string   "redirect_uri",      limit: 2048, null: false
    t.datetime "created_at",                     null: false
    t.datetime "revoked_at"
    t.string   "scopes"
  end

  add_index "oauth_access_grants", ["token"], name: "index_oauth_access_grants_on_token", unique: true, using: :btree

  create_table "oauth_access_tokens", force: true do |t|
    t.integer  "resource_owner_id"
    t.integer  "application_id",    null: false
    t.string   "token",             null: false
    t.string   "refresh_token"
    t.integer  "expires_in"
    t.datetime "revoked_at"
    t.datetime "created_at",        null: false
    t.string   "scopes"
  end

  add_index "oauth_access_tokens", ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true, using: :btree
  add_index "oauth_access_tokens", ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id", using: :btree
  add_index "oauth_access_tokens", ["token"], name: "index_oauth_access_tokens_on_token", unique: true, using: :btree

  create_table "oauth_applications", force: true do |t|
    t.string   "name",                                   null: false
    t.string   "uid",                                    null: false
    t.string   "secret",                                 null: false
    t.string   "redirect_uri", limit: 2048,              null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "scopes",                    default: "", null: false
  end

  add_index "oauth_applications", ["uid"], name: "index_oauth_applications_on_uid", unique: true, using: :btree

  create_table "open_id_authentication_associations", force: true do |t|
    t.integer "issued"
    t.integer "lifetime"
    t.string  "handle"
    t.string  "assoc_type"
    t.binary  "server_url"
    t.binary  "secret"
  end

  create_table "open_id_authentication_nonces", force: true do |t|
    t.integer "timestamp",  null: false
    t.string  "server_url"
    t.string  "salt",       null: false
  end

  create_table "passages", force: true do |t|
    t.integer  "user_id",                                                             null: false
    t.integer  "length",                                              default: 1,     null: false
    t.string   "reference",        limit: 50
    t.string   "translation",      limit: 10,                                         null: false
    t.string   "book",             limit: 40,                                         null: false
    t.integer  "chapter",                                                             null: false
    t.integer  "first_verse",                                                         null: false
    t.integer  "last_verse",                                                          null: false
    t.boolean  "complete_chapter",                                    default: false
    t.boolean  "synched",                                             default: false
    t.decimal  "efactor",                     precision: 4, scale: 1, default: 2.0
    t.integer  "test_interval",                                       default: 1
    t.integer  "rep_n",                                               default: 1
    t.date     "next_test"
    t.date     "last_tested"
    t.datetime "created_at",                                                          null: false
    t.datetime "updated_at",                                                          null: false
    t.integer  "book_index"
  end

  add_index "passages", ["book_index"], name: "index_passages_on_book_index", using: :btree
  add_index "passages", ["user_id"], name: "index_passages_on_user_id", using: :btree

  create_table "passwords", force: true do |t|
    t.integer  "user_id"
    t.string   "reset_code"
    t.datetime "expiration_date"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "pastors", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "pastors", ["name"], name: "index_pastors_on_name", using: :btree

  create_table "popverses", force: true do |t|
    t.string   "pop_ref",    null: false
    t.integer  "num_users",  null: false
    t.string   "book",       null: false
    t.string   "chapter",    null: false
    t.string   "versenum",   null: false
    t.integer  "niv"
    t.integer  "esv"
    t.integer  "nas"
    t.integer  "nkj"
    t.integer  "kjv"
    t.integer  "rsv"
    t.string   "niv_text"
    t.string   "esv_text"
    t.string   "nas_text"
    t.string   "nkj_text"
    t.string   "kjv_text"
    t.string   "rsv_text"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "progress_reports", force: true do |t|
    t.integer "user_id",         null: false
    t.date    "entry_date"
    t.integer "learning"
    t.integer "memorized"
    t.integer "time_allocation"
    t.integer "consistency"
  end

  add_index "progress_reports", ["user_id"], name: "index_progress_reports_on_user_id", using: :btree

  create_table "quests", force: true do |t|
    t.integer  "level"
    t.string   "task"
    t.text     "description"
    t.string   "objective"
    t.string   "qualifier"
    t.integer  "quantity"
    t.string   "url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "badge_id"
  end

  add_index "quests", ["level"], name: "index_quests_on_level", using: :btree
  add_index "quests", ["objective"], name: "index_quests_on_objective", using: :btree
  add_index "quests", ["qualifier"], name: "index_quests_on_qualifier", using: :btree

  create_table "quests_users", id: false, force: true do |t|
    t.integer "quest_id"
    t.integer "user_id"
  end

  create_table "quiz_questions", force: true do |t|
    t.integer  "quiz_id",                                                         null: false
    t.integer  "question_no"
    t.string   "question_type"
    t.string   "passage"
    t.text     "mc_question"
    t.string   "mc_option_a"
    t.string   "mc_option_b"
    t.string   "mc_option_c"
    t.string   "mc_option_d"
    t.string   "mc_answer"
    t.integer  "times_answered",                           default: 0
    t.decimal  "perc_correct",    precision: 10, scale: 0, default: 50
    t.string   "mcq_category"
    t.date     "last_asked",                               default: '2012-10-22'
    t.integer  "supporting_ref"
    t.integer  "submitted_by"
    t.string   "approval_status",                          default: "Pending"
    t.string   "rejection_code"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "quiz_questions", ["approval_status"], name: "index_quiz_questions_on_approval_status", using: :btree

  create_table "quizzes", force: true do |t|
    t.integer  "user_id",              null: false
    t.string   "name"
    t.text     "description"
    t.integer  "quiz_questions_count"
    t.datetime "start_time"
    t.integer  "quiz_length"
  end

  create_table "rails_admin_histories", force: true do |t|
    t.text     "message"
    t.string   "username"
    t.integer  "item"
    t.string   "table"
    t.integer  "month",      limit: 2
    t.integer  "year",       limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "rails_admin_histories", ["item", "table", "month", "year"], name: "index_rails_admin_histories", using: :btree

  create_table "roles", force: true do |t|
    t.string "name"
  end

  create_table "roles_users", id: false, force: true do |t|
    t.integer "role_id"
    t.integer "user_id"
  end

  create_table "rpush_apps", force: true do |t|
    t.string   "name",                                null: false
    t.string   "environment"
    t.text     "certificate"
    t.string   "password"
    t.integer  "connections",             default: 1, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "type",                                null: false
    t.string   "auth_key"
    t.string   "client_id"
    t.string   "client_secret"
    t.string   "access_token"
    t.datetime "access_token_expiration"
  end

  create_table "rpush_feedback", force: true do |t|
    t.string   "device_token", limit: 64, null: false
    t.datetime "failed_at",               null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "app_id"
  end

  add_index "rpush_feedback", ["device_token"], name: "index_rpush_feedback_on_device_token", using: :btree

  create_table "rpush_notifications", force: true do |t|
    t.integer  "badge"
    t.string   "device_token",      limit: 64
    t.string   "sound",                              default: "default"
    t.string   "alert"
    t.text     "data"
    t.integer  "expiry",                             default: 86400
    t.boolean  "delivered",                          default: false,     null: false
    t.datetime "delivered_at"
    t.boolean  "failed",                             default: false,     null: false
    t.datetime "failed_at"
    t.integer  "error_code"
    t.text     "error_description"
    t.datetime "deliver_after"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "alert_is_json",                      default: false
    t.string   "type",                                                   null: false
    t.string   "collapse_key"
    t.boolean  "delay_while_idle",                   default: false,     null: false
    t.text     "registration_ids",  limit: 16777215
    t.integer  "app_id",                                                 null: false
    t.integer  "retries",                            default: 0
    t.string   "uri"
    t.datetime "fail_after"
    t.boolean  "processing",                         default: false,     null: false
    t.integer  "priority"
    t.text     "url_args"
    t.string   "category"
    t.boolean  "content_available",                  default: false
  end

  add_index "rpush_notifications", ["app_id", "delivered", "failed", "deliver_after"], name: "index_rapns_notifications_multi", using: :btree
  add_index "rpush_notifications", ["delivered", "failed"], name: "index_rpush_notifications_multi", using: :btree

  create_table "sermons", force: true do |t|
    t.string   "title"
    t.text     "summary"
    t.integer  "church_id"
    t.integer  "pastor_id"
    t.integer  "user_id"
    t.integer  "uberverse_id"
    t.string   "mp3_file_name"
    t.string   "mp3_content_type"
    t.integer  "mp3_file_size"
    t.datetime "mp3_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sermons", ["church_id"], name: "index_sermons_on_church_id", using: :btree
  add_index "sermons", ["pastor_id"], name: "index_sermons_on_pastor_id", using: :btree
  add_index "sermons", ["title"], name: "index_sermons_on_title", using: :btree
  add_index "sermons", ["uberverse_id"], name: "index_sermons_on_uberverse_id", using: :btree
  add_index "sermons", ["user_id"], name: "index_sermons_on_user_id", using: :btree

  create_table "sessions", force: true do |t|
    t.string   "session_id", null: false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], name: "index_sessions_on_session_id", using: :btree
  add_index "sessions", ["updated_at"], name: "index_sessions_on_updated_at", using: :btree

  create_table "taggings", force: true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.integer  "tagger_id"
    t.string   "tagger_type"
    t.string   "taggable_type"
    t.string   "context"
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id"], name: "index_taggings_on_tag_id", using: :btree
  add_index "taggings", ["taggable_id", "taggable_type", "context"], name: "index_taggings_on_taggable_id_and_taggable_type_and_context", using: :btree

  create_table "tags", force: true do |t|
    t.string  "name"
    t.integer "taggings_count", default: 0
  end

  create_table "tweets", force: true do |t|
    t.integer  "importance",        default: 5
    t.integer  "user_id"
    t.integer  "church_id"
    t.integer  "american_state_id"
    t.integer  "country_id"
    t.string   "news"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "group_id"
  end

  add_index "tweets", ["american_state_id"], name: "index_tweets_on_american_state_id", using: :btree
  add_index "tweets", ["church_id"], name: "index_tweets_on_church_id", using: :btree
  add_index "tweets", ["country_id"], name: "index_tweets_on_country_id", using: :btree
  add_index "tweets", ["importance"], name: "index_tweets_on_importance", using: :btree
  add_index "tweets", ["user_id"], name: "index_tweets_on_user_id", using: :btree

  create_table "uberverses", force: true do |t|
    t.string  "book",           null: false
    t.integer "chapter",        null: false
    t.integer "versenum",       null: false
    t.integer "book_index"
    t.integer "subsection_end"
  end

  add_index "uberverses", ["book"], name: "index_uberverses_on_book", using: :btree
  add_index "uberverses", ["book_index"], name: "index_uberverses_on_book_index", using: :btree
  add_index "uberverses", ["chapter"], name: "index_uberverses_on_chapter", using: :btree
  add_index "uberverses", ["versenum"], name: "index_uberverses_on_versenum", using: :btree

  create_table "uberverses_sermons", id: false, force: true do |t|
    t.integer "uberverse_id"
    t.integer "sermon_id"
    t.boolean "primary_verse", default: false
  end

  create_table "users", force: true do |t|
    t.string   "login",                     limit: 40
    t.string   "identity_url"
    t.string   "name",                      limit: 100, default: ""
    t.string   "email",                     limit: 100
    t.string   "encrypted_password",        limit: 128, default: "",               null: false
    t.string   "password_salt",                         default: "",               null: false
    t.string   "remember_token",            limit: 40
    t.string   "confirmation_token"
    t.datetime "remember_token_expires_at"
    t.datetime "confirmed_at"
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.date     "last_reminder"
    t.string   "reminder_freq",                         default: "weekly"
    t.boolean  "newsletters",                           default: true
    t.integer  "church_id"
    t.integer  "country_id"
    t.string   "language",                              default: "English"
    t.integer  "time_allocation",                       default: 5
    t.integer  "memorized",                             default: 0
    t.integer  "learning",                              default: 0
    t.date     "last_activity_date"
    t.boolean  "show_echo",                             default: true
    t.integer  "max_interval",                          default: 366
    t.string   "mnemonic_use",                          default: "Learning"
    t.integer  "american_state_id"
    t.integer  "accuracy",                              default: 10
    t.boolean  "all_refs",                              default: true
    t.integer  "rank"
    t.integer  "ref_grade",                             default: 10
    t.string   "gender"
    t.string   "translation"
    t.integer  "level",                                 default: 0,                null: false
    t.integer  "referred_by"
    t.boolean  "show_email",                            default: false
    t.boolean  "auto_work_load",                        default: true
    t.datetime "confirmation_sent_at"
    t.string   "reset_password_token"
    t.datetime "remember_created_at"
    t.boolean  "admin",                                 default: false
    t.integer  "group_id"
    t.datetime "reset_password_sent_at"
    t.boolean  "forem_admin",                           default: false
    t.string   "forem_state",                           default: "pending_review"
    t.boolean  "forem_auto_subscribe",                  default: false
    t.string   "unconfirmed_email"
    t.string   "provider"
    t.string   "uid"
    t.boolean  "sync_subsections",                      default: false
  end

  add_index "users", ["american_state_id"], name: "index_users_on_american_state_id", using: :btree
  add_index "users", ["church_id"], name: "index_users_on_church_id", using: :btree
  add_index "users", ["country_id"], name: "index_users_on_country_id", using: :btree
  add_index "users", ["last_activity_date"], name: "index_users_on_last_activity_date", using: :btree
  add_index "users", ["login"], name: "index_users_on_login", unique: true, using: :btree
  add_index "users", ["referred_by"], name: "index_users_on_referred_by", using: :btree

  create_table "verses", force: true do |t|
    t.string   "translation",                                             null: false
    t.integer  "book_index",                                              null: false
    t.string   "book",                                                    null: false
    t.integer  "chapter",                                                 null: false
    t.integer  "versenum",                                                null: false
    t.text     "text"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "verified",                                default: false, null: false
    t.boolean  "error_flag",                              default: false, null: false
    t.integer  "uberverse_id"
    t.string   "checked_by"
    t.integer  "memverses_count",                         default: 0
    t.decimal  "difficulty",      precision: 5, scale: 2
    t.decimal  "popularity",      precision: 5, scale: 2
  end

  add_index "verses", ["book"], name: "index_verses_on_book", using: :btree
  add_index "verses", ["book_index"], name: "index_verses_on_book_index", using: :btree
  add_index "verses", ["chapter"], name: "index_verses_on_chapter", using: :btree
  add_index "verses", ["error_flag"], name: "index_verses_on_error_flag", using: :btree
  add_index "verses", ["translation", "book", "chapter", "versenum"], name: "index_verses_on_translation_and_book_and_chapter_and_versenum", unique: true, using: :btree
  add_index "verses", ["translation"], name: "index_verses_on_translation", using: :btree
  add_index "verses", ["verified"], name: "index_verses_on_verified", using: :btree
  add_index "verses", ["versenum"], name: "index_verses_on_versenum", using: :btree

end
