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

ActiveRecord::Schema.define(version: 20161114183340) do

  create_table "american_states", force: :cascade do |t|
    t.string  "abbrev",      limit: 20,  default: "", null: false
    t.string  "name",        limit: 50,  default: "", null: false
    t.integer "users_count", limit: 4,   default: 0
    t.integer "population",  limit: 4
    t.integer "rank",        limit: 4
    t.string  "slug",        limit: 255
  end

  add_index "american_states", ["name"], name: "index_american_states_on_name", unique: true
  add_index "american_states", ["slug"], name: "index_american_states_on_slug"
  add_index "american_states", ["users_count"], name: "index_american_states_on_users_count"

  create_table "badges", force: :cascade do |t|
    t.string   "name",        limit: 255
    t.text     "description", limit: 65535
    t.string   "color",       limit: 255
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  create_table "badges_users", id: false, force: :cascade do |t|
    t.integer "badge_id", limit: 4
    t.integer "user_id",  limit: 4
  end

  create_table "bloggity_blog_assets", force: :cascade do |t|
    t.integer "blog_post_id", limit: 4
    t.integer "parent_id",    limit: 4
    t.string  "content_type", limit: 255
    t.string  "filename",     limit: 255
    t.string  "thumbnail",    limit: 255
    t.integer "size",         limit: 4
    t.integer "width",        limit: 4
    t.integer "height",       limit: 4
  end

  create_table "bloggity_blog_categories", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.integer  "parent_id",  limit: 4
    t.integer  "blog_id",    limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "bloggity_blog_categories", ["blog_id"], name: "index_blog_categories_on_blog_id"
  add_index "bloggity_blog_categories", ["parent_id"], name: "index_blog_categories_on_parent_id"

  create_table "bloggity_blog_comments", force: :cascade do |t|
    t.integer  "user_id",      limit: 4
    t.integer  "blog_post_id", limit: 4
    t.text     "comment",      limit: 65535
    t.boolean  "approved"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "bloggity_blog_comments", ["blog_post_id"], name: "index_blog_comments_on_blog_post_id"

  create_table "bloggity_blog_posts", force: :cascade do |t|
    t.string   "title",           limit: 255
    t.text     "body",            limit: 65535
    t.string   "tag_string",      limit: 255
    t.integer  "posted_by_id",    limit: 4
    t.boolean  "is_complete"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "url_identifier",  limit: 255
    t.boolean  "comments_closed"
    t.integer  "category_id",     limit: 4
    t.integer  "blog_id",         limit: 4,     default: 1
    t.boolean  "fck_created"
    t.boolean  "tweeted",                       default: false
  end

  add_index "bloggity_blog_posts", ["blog_id"], name: "index_blog_posts_on_blog_id"
  add_index "bloggity_blog_posts", ["category_id"], name: "index_blog_posts_on_category_id"
  add_index "bloggity_blog_posts", ["url_identifier"], name: "index_blog_posts_on_url_identifier"

  create_table "bloggity_blog_tags", force: :cascade do |t|
    t.string   "name",         limit: 255
    t.integer  "blog_post_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "bloggity_blog_tags", ["blog_post_id"], name: "index_blog_tags_on_blog_post_id"

  create_table "bloggity_blogs", force: :cascade do |t|
    t.string   "title",          limit: 255
    t.string   "subtitle",       limit: 255
    t.string   "url_identifier", limit: 255
    t.string   "stylesheet",     limit: 255
    t.string   "feedburner_url", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "bloggity_blogs", ["url_identifier"], name: "index_blogs_on_url_identifier"

  create_table "churches", force: :cascade do |t|
    t.string   "name",        limit: 255,               null: false
    t.text     "description", limit: 65535
    t.integer  "country_id",  limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "users_count", limit: 4,     default: 0
    t.integer  "rank",        limit: 4
  end

  add_index "churches", ["name"], name: "index_churches_on_name", unique: true
  add_index "churches", ["users_count"], name: "index_churches_on_users_count"

  create_table "ckeditor_assets", force: :cascade do |t|
    t.string   "data_file_name",    limit: 255, null: false
    t.string   "data_content_type", limit: 255
    t.integer  "data_file_size",    limit: 4
    t.integer  "assetable_id",      limit: 4
    t.string   "assetable_type",    limit: 30
    t.string   "type",              limit: 30
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "ckeditor_assets", ["assetable_type", "assetable_id"], name: "idx_ckeditor_assetable"
  add_index "ckeditor_assets", ["assetable_type", "type", "assetable_id"], name: "idx_ckeditor_assetable_type"

  create_table "countries", force: :cascade do |t|
    t.string  "iso",            limit: 2,               null: false
    t.string  "name",           limit: 80,              null: false
    t.string  "printable_name", limit: 80,              null: false
    t.string  "iso3",           limit: 3
    t.integer "numcode",        limit: 2
    t.integer "users_count",    limit: 4,   default: 0
    t.integer "rank",           limit: 4
    t.string  "slug",           limit: 255
  end

  add_index "countries", ["printable_name"], name: "index_countries_on_printable_name", unique: true
  add_index "countries", ["slug"], name: "index_countries_on_slug"
  add_index "countries", ["users_count"], name: "index_countries_on_users_count"

  create_table "daily_stats", force: :cascade do |t|
    t.date    "entry_date",                                                        null: false
    t.integer "users",                              limit: 4
    t.integer "users_active_in_month",              limit: 4
    t.integer "verses",                             limit: 4
    t.integer "memverses",                          limit: 4
    t.integer "memverses_learning",                 limit: 4
    t.integer "memverses_memorized",                limit: 4
    t.integer "memverses_learning_active_in_month", limit: 4
    t.integer "memverses_memorized_not_overdue",    limit: 4
    t.string  "segment",                            limit: 255, default: "Global"
  end

  add_index "daily_stats", ["segment"], name: "index_daily_stats_on_segment"

  create_table "devotions", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.string   "ref",        limit: 255
    t.text     "thought",    limit: 65535
    t.integer  "month",      limit: 4
    t.integer  "day",        limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "devotions", ["day"], name: "index_devotions_on_day"
  add_index "devotions", ["month"], name: "index_devotions_on_month"
  add_index "devotions", ["name"], name: "index_devotions_on_name"

  create_table "final_verses", force: :cascade do |t|
    t.string  "book",       limit: 255, null: false
    t.integer "chapter",    limit: 4,   null: false
    t.integer "last_verse", limit: 4,   null: false
  end

  add_index "final_verses", ["book", "chapter"], name: "index_final_verses_on_book_and_chapter"

  create_table "forem_categories", force: :cascade do |t|
    t.string   "name",       limit: 255,             null: false
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
    t.string   "slug",       limit: 255
    t.integer  "position",   limit: 4,   default: 0
  end

  add_index "forem_categories", ["slug"], name: "index_forem_categories_on_slug", unique: true

  create_table "forem_forums", force: :cascade do |t|
    t.string  "name",        limit: 255
    t.text    "description", limit: 65535
    t.integer "category_id", limit: 4
    t.integer "views_count", limit: 4,     default: 0
    t.string  "slug",        limit: 255
    t.integer "position",    limit: 4,     default: 0
  end

  add_index "forem_forums", ["slug"], name: "index_forem_forums_on_slug", unique: true

  create_table "forem_groups", force: :cascade do |t|
    t.string "name", limit: 255
  end

  add_index "forem_groups", ["name"], name: "index_forem_groups_on_name"

  create_table "forem_memberships", force: :cascade do |t|
    t.integer "group_id",  limit: 4
    t.integer "member_id", limit: 4
  end

  add_index "forem_memberships", ["group_id"], name: "index_forem_memberships_on_group_id"

  create_table "forem_moderator_groups", force: :cascade do |t|
    t.integer "forum_id", limit: 4
    t.integer "group_id", limit: 4
  end

  add_index "forem_moderator_groups", ["forum_id"], name: "index_forem_moderator_groups_on_forum_id"

  create_table "forem_posts", force: :cascade do |t|
    t.integer  "topic_id",    limit: 4
    t.text     "text",        limit: 65535
    t.integer  "user_id",     limit: 4
    t.datetime "created_at",                                           null: false
    t.datetime "updated_at",                                           null: false
    t.integer  "reply_to_id", limit: 4
    t.string   "state",       limit: 255,   default: "pending_review"
    t.boolean  "notified",                  default: false
  end

  add_index "forem_posts", ["reply_to_id"], name: "index_forem_posts_on_reply_to_id"
  add_index "forem_posts", ["state"], name: "index_forem_posts_on_state"
  add_index "forem_posts", ["topic_id"], name: "index_forem_posts_on_topic_id"
  add_index "forem_posts", ["user_id"], name: "index_forem_posts_on_user_id"

  create_table "forem_subscriptions", force: :cascade do |t|
    t.integer "subscriber_id", limit: 4
    t.integer "topic_id",      limit: 4
  end

  create_table "forem_topics", force: :cascade do |t|
    t.integer  "forum_id",     limit: 4
    t.integer  "user_id",      limit: 4
    t.string   "subject",      limit: 255
    t.datetime "created_at",                                          null: false
    t.datetime "updated_at",                                          null: false
    t.boolean  "locked",                   default: false,            null: false
    t.boolean  "pinned",                   default: false
    t.boolean  "hidden",                   default: false
    t.datetime "last_post_at"
    t.string   "state",        limit: 255, default: "pending_review"
    t.integer  "views_count",  limit: 4,   default: 0
    t.string   "slug",         limit: 255
  end

  add_index "forem_topics", ["forum_id"], name: "index_forem_topics_on_forum_id"
  add_index "forem_topics", ["slug"], name: "index_forem_topics_on_slug", unique: true
  add_index "forem_topics", ["state"], name: "index_forem_topics_on_state"
  add_index "forem_topics", ["user_id"], name: "index_forem_topics_on_user_id"

  create_table "forem_views", force: :cascade do |t|
    t.integer  "user_id",           limit: 4
    t.integer  "viewable_id",       limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "count",             limit: 4,   default: 0
    t.string   "viewable_type",     limit: 255
    t.datetime "current_viewed_at"
    t.datetime "past_viewed_at"
  end

  add_index "forem_views", ["updated_at"], name: "index_forem_views_on_updated_at"
  add_index "forem_views", ["user_id"], name: "index_forem_views_on_user_id"
  add_index "forem_views", ["viewable_id"], name: "index_forem_views_on_topic_id"

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.string   "slug",           limit: 191, null: false
    t.integer  "sluggable_id",   limit: 4,   null: false
    t.string   "sluggable_type", limit: 50
    t.string   "scope",          limit: 191
    t.datetime "created_at"
  end

  add_index "friendly_id_slugs", ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
  add_index "friendly_id_slugs", ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
  add_index "friendly_id_slugs", ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id"
  add_index "friendly_id_slugs", ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type"

  create_table "groups", force: :cascade do |t|
    t.string   "name",        limit: 255,               null: false
    t.text     "description", limit: 65535
    t.integer  "rank",        limit: 4
    t.integer  "users_count", limit: 4,     default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "leader_id",   limit: 4
  end

  create_table "memverses", force: :cascade do |t|
    t.integer  "user_id",       limit: 4,                                         null: false
    t.integer  "verse_id",      limit: 4,                                         null: false
    t.decimal  "efactor",                   precision: 5, scale: 1, default: 0.0
    t.integer  "test_interval", limit: 4,                           default: 1
    t.integer  "rep_n",         limit: 4,                           default: 1
    t.date     "next_test"
    t.date     "last_tested"
    t.string   "status",        limit: 255
    t.integer  "attempts",      limit: 4,                           default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "first_verse",   limit: 4
    t.integer  "prev_verse",    limit: 4
    t.integer  "next_verse",    limit: 4
    t.integer  "ref_interval",  limit: 4,                           default: 1
    t.date     "next_ref_test"
    t.integer  "uberverse_id",  limit: 4
    t.integer  "passage_id",    limit: 4
    t.integer  "subsection",    limit: 4
  end

  add_index "memverses", ["passage_id"], name: "index_memverses_on_passage_id"
  add_index "memverses", ["status"], name: "index_memverses_on_status"
  add_index "memverses", ["user_id", "verse_id"], name: "index_memverses_on_user_id_and_verse_id", unique: true
  add_index "memverses", ["user_id"], name: "index_memverses_on_user_id"
  add_index "memverses", ["verse_id"], name: "index_memverses_on_verse_id"

  create_table "oauth_access_grants", force: :cascade do |t|
    t.integer  "resource_owner_id", limit: 4,    null: false
    t.integer  "application_id",    limit: 4,    null: false
    t.string   "token",             limit: 255,  null: false
    t.integer  "expires_in",        limit: 4,    null: false
    t.string   "redirect_uri",      limit: 2048, null: false
    t.datetime "created_at",                     null: false
    t.datetime "revoked_at"
    t.string   "scopes",            limit: 255
  end

  add_index "oauth_access_grants", ["token"], name: "index_oauth_access_grants_on_token", unique: true

  create_table "oauth_access_tokens", force: :cascade do |t|
    t.integer  "resource_owner_id", limit: 4
    t.integer  "application_id",    limit: 4,   null: false
    t.string   "token",             limit: 255, null: false
    t.string   "refresh_token",     limit: 255
    t.integer  "expires_in",        limit: 4
    t.datetime "revoked_at"
    t.datetime "created_at",                    null: false
    t.string   "scopes",            limit: 255
  end

  add_index "oauth_access_tokens", ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true
  add_index "oauth_access_tokens", ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id"
  add_index "oauth_access_tokens", ["token"], name: "index_oauth_access_tokens_on_token", unique: true

  create_table "oauth_applications", force: :cascade do |t|
    t.string   "name",         limit: 255,               null: false
    t.string   "uid",          limit: 255,               null: false
    t.string   "secret",       limit: 255,               null: false
    t.string   "redirect_uri", limit: 2048,              null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "scopes",       limit: 255,  default: "", null: false
  end

  add_index "oauth_applications", ["uid"], name: "index_oauth_applications_on_uid", unique: true

  create_table "open_id_authentication_associations", force: :cascade do |t|
    t.integer "issued",     limit: 4
    t.integer "lifetime",   limit: 4
    t.string  "handle",     limit: 255
    t.string  "assoc_type", limit: 255
    t.binary  "server_url"
    t.binary  "secret"
  end

  create_table "open_id_authentication_nonces", force: :cascade do |t|
    t.integer "timestamp",  limit: 4,   null: false
    t.string  "server_url", limit: 255
    t.string  "salt",       limit: 255, null: false
  end

  create_table "passages", force: :cascade do |t|
    t.integer  "user_id",          limit: 4,                                          null: false
    t.integer  "length",           limit: 4,                          default: 1,     null: false
    t.string   "reference",        limit: 50
    t.string   "translation",      limit: 10,                                         null: false
    t.string   "book",             limit: 40,                                         null: false
    t.integer  "chapter",          limit: 4,                                          null: false
    t.integer  "first_verse",      limit: 4,                                          null: false
    t.integer  "last_verse",       limit: 4,                                          null: false
    t.boolean  "complete_chapter",                                    default: false
    t.boolean  "synched",                                             default: false
    t.decimal  "efactor",                     precision: 4, scale: 1, default: 2.0
    t.integer  "test_interval",    limit: 4,                          default: 1
    t.integer  "rep_n",            limit: 4,                          default: 1
    t.date     "next_test"
    t.date     "last_tested"
    t.datetime "created_at",                                                          null: false
    t.datetime "updated_at",                                                          null: false
    t.integer  "book_index",       limit: 4
  end

  add_index "passages", ["book_index"], name: "index_passages_on_book_index"
  add_index "passages", ["user_id"], name: "index_passages_on_user_id"

  create_table "passwords", force: :cascade do |t|
    t.integer  "user_id",         limit: 4
    t.string   "reset_code",      limit: 255
    t.datetime "expiration_date"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "pastors", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "pastors", ["name"], name: "index_pastors_on_name"

  create_table "popverses", force: :cascade do |t|
    t.string   "pop_ref",    limit: 255, null: false
    t.integer  "num_users",  limit: 4,   null: false
    t.string   "book",       limit: 255, null: false
    t.string   "chapter",    limit: 255, null: false
    t.string   "versenum",   limit: 255, null: false
    t.integer  "niv",        limit: 4
    t.integer  "esv",        limit: 4
    t.integer  "nas",        limit: 4
    t.integer  "nkj",        limit: 4
    t.integer  "kjv",        limit: 4
    t.integer  "rsv",        limit: 4
    t.string   "niv_text",   limit: 300
    t.string   "esv_text",   limit: 300
    t.string   "nas_text",   limit: 300
    t.string   "nkj_text",   limit: 300
    t.string   "kjv_text",   limit: 300
    t.string   "rsv_text",   limit: 300
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "progress_reports", force: :cascade do |t|
    t.integer "user_id",         limit: 4, null: false
    t.date    "entry_date"
    t.integer "learning",        limit: 4
    t.integer "memorized",       limit: 4
    t.integer "time_allocation", limit: 4
    t.integer "consistency",     limit: 4
  end

  add_index "progress_reports", ["user_id"], name: "index_progress_reports_on_user_id"

  create_table "quests", force: :cascade do |t|
    t.integer  "level",       limit: 4
    t.string   "task",        limit: 255
    t.text     "description", limit: 65535
    t.string   "objective",   limit: 255
    t.string   "qualifier",   limit: 255
    t.integer  "quantity",    limit: 4
    t.string   "url",         limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "badge_id",    limit: 4
  end

  add_index "quests", ["level"], name: "index_quests_on_level"
  add_index "quests", ["objective"], name: "index_quests_on_objective"
  add_index "quests", ["qualifier"], name: "index_quests_on_qualifier"

  create_table "quests_users", id: false, force: :cascade do |t|
    t.integer "quest_id", limit: 4
    t.integer "user_id",  limit: 4
  end

  create_table "quiz_questions", force: :cascade do |t|
    t.integer  "quiz_id",         limit: 4,                                           null: false
    t.integer  "question_no",     limit: 4
    t.string   "question_type",   limit: 255
    t.string   "passage",         limit: 255
    t.text     "mc_question",     limit: 65535
    t.string   "mc_option_a",     limit: 255
    t.string   "mc_option_b",     limit: 255
    t.string   "mc_option_c",     limit: 255
    t.string   "mc_option_d",     limit: 255
    t.string   "mc_answer",       limit: 255
    t.integer  "times_answered",  limit: 4,                    default: 0
    t.decimal  "perc_correct",                  precision: 10, default: 50
    t.string   "mcq_category",    limit: 255
    t.date     "last_asked",                                   default: '2012-10-22'
    t.integer  "supporting_ref",  limit: 4
    t.integer  "submitted_by",    limit: 4
    t.string   "approval_status", limit: 255,                  default: "Pending"
    t.string   "rejection_code",  limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "quiz_questions", ["approval_status"], name: "index_quiz_questions_on_approval_status"

  create_table "quizzes", force: :cascade do |t|
    t.integer  "user_id",              limit: 4,     null: false
    t.string   "name",                 limit: 255
    t.text     "description",          limit: 65535
    t.integer  "quiz_questions_count", limit: 4
    t.datetime "start_time"
    t.integer  "quiz_length",          limit: 4
  end

  create_table "rails_admin_histories", force: :cascade do |t|
    t.text     "message",    limit: 65535
    t.string   "username",   limit: 255
    t.integer  "item",       limit: 4
    t.string   "table",      limit: 255
    t.integer  "month",      limit: 2
    t.integer  "year",       limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "rails_admin_histories", ["item", "table", "month", "year"], name: "index_rails_admin_histories"

  create_table "roles", force: :cascade do |t|
    t.string "name", limit: 255
  end

  create_table "roles_users", id: false, force: :cascade do |t|
    t.integer "role_id", limit: 4
    t.integer "user_id", limit: 4
  end

  create_table "rpush_apps", force: :cascade do |t|
    t.string   "name",                    limit: 255,               null: false
    t.string   "environment",             limit: 255
    t.text     "certificate",             limit: 65535
    t.string   "password",                limit: 255
    t.integer  "connections",             limit: 4,     default: 1, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "type",                    limit: 255,               null: false
    t.string   "auth_key",                limit: 255
    t.string   "client_id",               limit: 255
    t.string   "client_secret",           limit: 255
    t.string   "access_token",            limit: 255
    t.datetime "access_token_expiration"
  end

  create_table "rpush_feedback", force: :cascade do |t|
    t.string   "device_token", limit: 64, null: false
    t.datetime "failed_at",               null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "app_id",       limit: 4
  end

  add_index "rpush_feedback", ["device_token"], name: "index_rpush_feedback_on_device_token"

  create_table "rpush_notifications", force: :cascade do |t|
    t.integer  "badge",             limit: 4
    t.string   "device_token",      limit: 64
    t.string   "sound",             limit: 255,      default: "default"
    t.string   "alert",             limit: 255
    t.text     "data",              limit: 65535
    t.integer  "expiry",            limit: 4,        default: 86400
    t.boolean  "delivered",                          default: false,     null: false
    t.datetime "delivered_at"
    t.boolean  "failed",                             default: false,     null: false
    t.datetime "failed_at"
    t.integer  "error_code",        limit: 4
    t.text     "error_description", limit: 65535
    t.datetime "deliver_after"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "alert_is_json",                      default: false
    t.string   "type",              limit: 255,                          null: false
    t.string   "collapse_key",      limit: 255
    t.boolean  "delay_while_idle",                   default: false,     null: false
    t.text     "registration_ids",  limit: 16777215
    t.integer  "app_id",            limit: 4,                            null: false
    t.integer  "retries",           limit: 4,        default: 0
    t.string   "uri",               limit: 255
    t.datetime "fail_after"
    t.boolean  "processing",                         default: false,     null: false
    t.integer  "priority",          limit: 4
    t.text     "url_args",          limit: 65535
    t.string   "category",          limit: 255
    t.boolean  "content_available",                  default: false
  end

  add_index "rpush_notifications", ["app_id", "delivered", "failed", "deliver_after"], name: "index_rapns_notifications_multi"
  add_index "rpush_notifications", ["delivered", "failed"], name: "index_rpush_notifications_multi"

  create_table "sermons", force: :cascade do |t|
    t.string   "title",            limit: 255
    t.text     "summary",          limit: 65535
    t.integer  "church_id",        limit: 4
    t.integer  "pastor_id",        limit: 4
    t.integer  "user_id",          limit: 4
    t.integer  "uberverse_id",     limit: 4
    t.string   "mp3_file_name",    limit: 255
    t.string   "mp3_content_type", limit: 255
    t.integer  "mp3_file_size",    limit: 4
    t.datetime "mp3_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sermons", ["church_id"], name: "index_sermons_on_church_id"
  add_index "sermons", ["pastor_id"], name: "index_sermons_on_pastor_id"
  add_index "sermons", ["title"], name: "index_sermons_on_title"
  add_index "sermons", ["uberverse_id"], name: "index_sermons_on_uberverse_id"
  add_index "sermons", ["user_id"], name: "index_sermons_on_user_id"

  create_table "sessions", force: :cascade do |t|
    t.string   "session_id", limit: 255,   null: false
    t.text     "data",       limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], name: "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], name: "index_sessions_on_updated_at"

  create_table "taggings", force: :cascade do |t|
    t.integer  "tag_id",        limit: 4
    t.integer  "taggable_id",   limit: 4
    t.integer  "tagger_id",     limit: 4
    t.string   "tagger_type",   limit: 255
    t.string   "taggable_type", limit: 255
    t.string   "context",       limit: 255
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id"], name: "index_taggings_on_tag_id"
  add_index "taggings", ["taggable_id", "taggable_type", "context"], name: "index_taggings_on_taggable_id_and_taggable_type_and_context"

  create_table "tags", force: :cascade do |t|
    t.string  "name",           limit: 255
    t.integer "taggings_count", limit: 4,   default: 0
  end

  create_table "thredded_categories", force: :cascade do |t|
    t.integer  "messageboard_id", limit: 4,   null: false
    t.string   "name",            limit: 191, null: false
    t.string   "description",     limit: 255
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.string   "slug",            limit: 191, null: false
  end

  add_index "thredded_categories", ["messageboard_id", "slug"], name: "index_thredded_categories_on_messageboard_id_and_slug", unique: true
  add_index "thredded_categories", ["messageboard_id"], name: "index_thredded_categories_on_messageboard_id"
  add_index "thredded_categories", ["name"], name: "thredded_categories_name_ci"

  create_table "thredded_messageboard_groups", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.integer  "position",               null: false
  end

  add_index "thredded_messageboard_groups", ["name"], name: "index_thredded_messageboard_group_on_name", unique: true

  create_table "thredded_messageboard_users", force: :cascade do |t|
    t.integer  "thredded_user_detail_id",  limit: 4, null: false
    t.integer  "thredded_messageboard_id", limit: 4, null: false
    t.datetime "last_seen_at",                       null: false
  end

  add_index "thredded_messageboard_users", ["thredded_messageboard_id", "last_seen_at"], name: "index_thredded_messageboard_users_for_recently_active"
  add_index "thredded_messageboard_users", ["thredded_messageboard_id", "thredded_user_detail_id"], name: "index_thredded_messageboard_users_primary"
  add_index "thredded_messageboard_users", ["thredded_user_detail_id"], name: "fk_rails_06e42c62f5"

  create_table "thredded_messageboards", force: :cascade do |t|
    t.string   "name",                  limit: 191,               null: false
    t.string   "slug",                  limit: 191
    t.text     "description",           limit: 65535
    t.integer  "topics_count",          limit: 4,     default: 0
    t.integer  "posts_count",           limit: 4,     default: 0
    t.integer  "last_topic_id",         limit: 4
    t.integer  "messageboard_group_id", limit: 4
    t.datetime "created_at",                                      null: false
    t.datetime "updated_at",                                      null: false
    t.integer  "position",                                        null: false
  end

  add_index "thredded_messageboards", ["messageboard_group_id"], name: "index_thredded_messageboards_on_messageboard_group_id"
  add_index "thredded_messageboards", ["slug"], name: "index_thredded_messageboards_on_slug"

  create_table "thredded_post_moderation_records", force: :cascade do |t|
    t.integer  "post_id",                   limit: 4
    t.integer  "messageboard_id",           limit: 4
    t.text     "post_content",              limit: 65535
    t.integer  "post_user_id",              limit: 4
    t.text     "post_user_name",            limit: 65535
    t.integer  "moderator_id",              limit: 4
    t.integer  "moderation_state",          limit: 4,     null: false
    t.integer  "previous_moderation_state", limit: 4,     null: false
    t.datetime "created_at",                              null: false
  end

  add_index "thredded_post_moderation_records", ["messageboard_id", "created_at"], name: "index_thredded_moderation_records_for_display"

  create_table "thredded_post_notifications", force: :cascade do |t|
    t.string   "email",      limit: 191, null: false
    t.integer  "post_id",    limit: 4,   null: false
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.string   "post_type",  limit: 191
  end

  add_index "thredded_post_notifications", ["post_id", "post_type"], name: "index_thredded_post_notifications_on_post"

  create_table "thredded_posts", force: :cascade do |t|
    t.integer  "user_id",          limit: 4
    t.text     "content",          limit: 65535
    t.string   "ip",               limit: 255
    t.string   "source",           limit: 255,   default: "web"
    t.integer  "postable_id",      limit: 4,                     null: false
    t.integer  "messageboard_id",  limit: 4,                     null: false
    t.integer  "moderation_state", limit: 4,                     null: false
    t.datetime "created_at",                                     null: false
    t.datetime "updated_at",                                     null: false
  end

  create_table "thredded_private_posts", force: :cascade do |t|
    t.integer  "user_id"
    t.text     "content",     limit: 65535
    t.integer  "postable_id",               null: false
    t.string   "ip",          limit: 255
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  create_table "thredded_private_topics", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "last_user_id"
    t.string   "title",        limit: 255,             null: false
    t.string   "slug",         limit: 191,             null: false
    t.integer  "posts_count",              default: 0
    t.string   "hash_id",      limit: 191,             null: false
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
    t.datetime "last_post_at"
  end

  add_index "thredded_private_topics", ["hash_id"], name: "index_thredded_private_topics_on_hash_id"
  add_index "thredded_private_topics", ["slug"], name: "index_thredded_private_topics_on_slug"

  create_table "thredded_private_users", force: :cascade do |t|
    t.integer  "private_topic_id", limit: 4
    t.integer  "user_id",          limit: 4
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  add_index "thredded_private_users", ["private_topic_id"], name: "index_thredded_private_users_on_private_topic_id"
  add_index "thredded_private_users", ["user_id"], name: "index_thredded_private_users_on_user_id"

  create_table "thredded_topic_categories", force: :cascade do |t|
    t.integer "topic_id",    null: false
    t.integer "category_id", null: false
  end

  add_index "thredded_topic_categories", ["category_id"], name: "index_thredded_topic_categories_on_category_id"
  add_index "thredded_topic_categories", ["topic_id"], name: "index_thredded_topic_categories_on_topic_id"

  create_table "thredded_topics", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "last_user_id"
    t.string   "title",            limit: 255,                 null: false
    t.string   "slug",             limit: 191,                 null: false
    t.integer  "messageboard_id",                              null: false
    t.integer  "posts_count",                  default: 0,     null: false
    t.boolean  "sticky",                       default: false, null: false
    t.boolean  "locked",                       default: false, null: false
    t.string   "hash_id",          limit: 191,                 null: false
    t.string   "type",             limit: 191
    t.integer  "moderation_state",                             null: false
    t.datetime "created_at",                                   null: false
    t.datetime "updated_at",                                   null: false
    t.datetime "last_post_at"
  end

  add_index "thredded_topics", ["hash_id"], name: "index_thredded_topics_on_hash_id"
  add_index "thredded_topics", ["messageboard_id", "slug"], name: "index_thredded_topics_on_messageboard_id_and_slug", unique: true
  add_index "thredded_topics", ["messageboard_id"], name: "index_thredded_topics_on_messageboard_id"
  add_index "thredded_topics", ["moderation_state", "sticky", "updated_at"], name: "index_thredded_topics_for_display"
  add_index "thredded_topics", ["user_id"], name: "index_thredded_topics_on_user_id"

  create_table "thredded_user_details", force: :cascade do |t|
    t.integer  "user_id",                                 null: false
    t.datetime "latest_activity_at"
    t.integer  "posts_count",                 default: 0
    t.integer  "topics_count",                default: 0
    t.datetime "last_seen_at"
    t.integer  "moderation_state",            default: 0, null: false
    t.datetime "moderation_state_changed_at"
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
  end

  add_index "thredded_user_details", ["latest_activity_at"], name: "index_thredded_user_details_on_latest_activity_at"
  add_index "thredded_user_details", ["moderation_state", "moderation_state_changed_at"], name: "index_thredded_user_details_for_moderations"
  add_index "thredded_user_details", ["user_id"], name: "index_thredded_user_details_on_user_id"

  create_table "thredded_user_messageboard_preferences", force: :cascade do |t|
    t.integer  "user_id",                                 null: false
    t.integer  "messageboard_id",                         null: false
    t.boolean  "follow_topics_on_mention", default: true, null: false
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
    t.boolean  "followed_topic_emails",    default: true, null: false
  end

  add_index "thredded_user_messageboard_preferences", ["user_id", "messageboard_id"], name: "thredded_user_messageboard_preferences_user_id_messageboard_id", unique: true

  create_table "thredded_user_preferences", force: :cascade do |t|
    t.integer  "user_id",                                 null: false
    t.boolean  "follow_topics_on_mention", default: true, null: false
    t.boolean  "notify_on_message",        default: true, null: false
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
    t.boolean  "followed_topic_emails",    default: true, null: false
  end

  add_index "thredded_user_preferences", ["user_id"], name: "index_thredded_user_preferences_on_user_id"

  create_table "thredded_user_private_topic_read_states", force: :cascade do |t|
    t.integer  "user_id",                 null: false
    t.integer  "postable_id",             null: false
    t.integer  "page",        default: 1, null: false
    t.datetime "read_at",                 null: false
  end

  add_index "thredded_user_private_topic_read_states", ["user_id", "postable_id"], name: "thredded_user_private_topic_read_states_user_postable", unique: true

  create_table "thredded_user_topic_follows", force: :cascade do |t|
    t.integer  "user_id",              null: false
    t.integer  "topic_id",             null: false
    t.datetime "created_at",           null: false
    t.integer  "reason",     limit: 1
  end

  add_index "thredded_user_topic_follows", ["user_id", "topic_id"], name: "thredded_user_topic_follows_user_topic", unique: true

  create_table "thredded_user_topic_read_states", force: :cascade do |t|
    t.integer  "user_id",                 null: false
    t.integer  "postable_id",             null: false
    t.integer  "page",        default: 1, null: false
    t.datetime "read_at",                 null: false
  end

  add_index "thredded_user_topic_read_states", ["user_id", "postable_id"], name: "thredded_user_topic_read_states_user_postable", unique: true

  create_table "tweets", force: :cascade do |t|
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

  add_index "tweets", ["american_state_id"], name: "index_tweets_on_american_state_id"
  add_index "tweets", ["church_id"], name: "index_tweets_on_church_id"
  add_index "tweets", ["country_id"], name: "index_tweets_on_country_id"
  add_index "tweets", ["importance"], name: "index_tweets_on_importance"
  add_index "tweets", ["user_id"], name: "index_tweets_on_user_id"

  create_table "uberverses", force: :cascade do |t|
    t.string  "book",           null: false
    t.integer "chapter",        null: false
    t.integer "versenum",       null: false
    t.integer "book_index"
    t.integer "subsection_end"
  end

  add_index "uberverses", ["book"], name: "index_uberverses_on_book"
  add_index "uberverses", ["book_index"], name: "index_uberverses_on_book_index"
  add_index "uberverses", ["chapter"], name: "index_uberverses_on_chapter"
  add_index "uberverses", ["versenum"], name: "index_uberverses_on_versenum"

  create_table "uberverses_sermons", id: false, force: :cascade do |t|
    t.integer "uberverse_id"
    t.integer "sermon_id"
    t.boolean "primary_verse", default: false
  end

  create_table "users", force: :cascade do |t|
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
    t.boolean  "thredded_admin",                        default: false
    t.string   "forem_state",                           default: "pending_review"
    t.boolean  "forem_auto_subscribe",                  default: false
    t.string   "unconfirmed_email"
    t.string   "provider"
    t.string   "uid"
    t.boolean  "sync_subsections",                      default: false
    t.boolean  "quiz_alert",                            default: false
    t.string   "device_token"
    t.string   "device_type"
  end

  add_index "users", ["american_state_id"], name: "index_users_on_american_state_id"
  add_index "users", ["church_id"], name: "index_users_on_church_id"
  add_index "users", ["country_id"], name: "index_users_on_country_id"
  add_index "users", ["last_activity_date"], name: "index_users_on_last_activity_date"
  add_index "users", ["login"], name: "index_users_on_login", unique: true
  add_index "users", ["quiz_alert"], name: "index_users_on_quiz_alert"
  add_index "users", ["referred_by"], name: "index_users_on_referred_by"

  create_table "verses", force: :cascade do |t|
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

  add_index "verses", ["book"], name: "index_verses_on_book"
  add_index "verses", ["book_index"], name: "index_verses_on_book_index"
  add_index "verses", ["chapter"], name: "index_verses_on_chapter"
  add_index "verses", ["error_flag"], name: "index_verses_on_error_flag"
  add_index "verses", ["translation", "book", "chapter", "versenum"], name: "index_verses_on_translation_and_book_and_chapter_and_versenum", unique: true
  add_index "verses", ["translation"], name: "index_verses_on_translation"
  add_index "verses", ["verified"], name: "index_verses_on_verified"
  add_index "verses", ["versenum"], name: "index_verses_on_versenum"

end
