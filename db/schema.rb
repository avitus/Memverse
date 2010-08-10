# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 30) do

  create_table "american_states", :force => true do |t|
    t.string  "abbrev",      :limit => 20, :default => "", :null => false
    t.string  "name",        :limit => 50, :default => "", :null => false
    t.integer "users_count",               :default => 0
    t.integer "population"
    t.integer "rank"
  end

  create_table "blog_assets", :force => true do |t|
    t.integer "blog_post_id"
    t.integer "parent_id"
    t.string  "content_type"
    t.string  "filename"
    t.string  "thumbnail"
    t.integer "size"
    t.integer "width"
    t.integer "height"
  end

  create_table "blog_categories", :force => true do |t|
    t.string   "name"
    t.integer  "parent_id"
    t.integer  "blog_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "blog_categories", ["blog_id"], :name => "index_blog_categories_on_blog_id"
  add_index "blog_categories", ["parent_id"], :name => "index_blog_categories_on_parent_id"

  create_table "blog_comments", :force => true do |t|
    t.integer  "user_id"
    t.integer  "blog_post_id"
    t.text     "comment"
    t.boolean  "approved"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "blog_comments", ["blog_post_id"], :name => "index_blog_comments_on_blog_post_id"

  create_table "blog_posts", :force => true do |t|
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
    t.integer  "blog_id",         :default => 1
    t.boolean  "fck_created"
  end

  add_index "blog_posts", ["blog_id"], :name => "index_blog_posts_on_blog_id"
  add_index "blog_posts", ["category_id"], :name => "index_blog_posts_on_category_id"
  add_index "blog_posts", ["url_identifier"], :name => "index_blog_posts_on_url_identifier"

  create_table "blog_tags", :force => true do |t|
    t.string   "name"
    t.integer  "blog_post_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "blog_tags", ["blog_post_id"], :name => "index_blog_tags_on_blog_post_id"

  create_table "blogs", :force => true do |t|
    t.string   "title"
    t.string   "subtitle"
    t.string   "url_identifier"
    t.string   "stylesheet"
    t.string   "feedburner_url"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "blogs", ["url_identifier"], :name => "index_blogs_on_url_identifier"

  create_table "churches", :force => true do |t|
    t.string   "name",                       :null => false
    t.text     "description"
    t.integer  "country_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "users_count", :default => 0
    t.integer  "rank"
  end

  create_table "countries", :force => true do |t|
    t.string  "iso",            :limit => 2,                 :null => false
    t.string  "name",           :limit => 80,                :null => false
    t.string  "printable_name", :limit => 80,                :null => false
    t.string  "iso3",           :limit => 3
    t.integer "numcode",        :limit => 2
    t.integer "users_count",                  :default => 0
    t.integer "rank"
  end

  create_table "daily_stats", :force => true do |t|
    t.date    "entry_date",                                               :null => false
    t.integer "users"
    t.integer "users_active_in_month"
    t.integer "verses"
    t.integer "memverses"
    t.integer "memverses_learning"
    t.integer "memverses_memorized"
    t.integer "memverses_learning_active_in_month"
    t.integer "memverses_memorized_not_overdue"
    t.string  "segment",                            :default => "Global"
  end

  create_table "final_verses", :force => true do |t|
    t.string  "book",       :null => false
    t.integer "chapter",    :null => false
    t.integer "last_verse", :null => false
  end

  add_index "final_verses", ["book", "chapter"], :name => "index_final_verses_on_book_and_chapter"

  create_table "memverses", :force => true do |t|
    t.integer  "user_id",                                                      :null => false
    t.integer  "verse_id",                                                     :null => false
    t.decimal  "efactor",       :precision => 5, :scale => 1, :default => 0.0
    t.integer  "test_interval",                               :default => 1
    t.integer  "rep_n",                                       :default => 1
    t.date     "next_test"
    t.date     "last_tested"
    t.string   "status"
    t.integer  "attempts",                                    :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "first_verse"
    t.integer  "prev_verse"
    t.integer  "next_verse"
    t.integer  "ref_interval",                                :default => 1
    t.date     "next_ref_test"
  end

  add_index "memverses", ["user_id", "verse_id"], :name => "index_memverses_on_user_id_and_verse_id", :unique => true
  add_index "memverses", ["user_id"], :name => "index_memverses_on_user_id"
  add_index "memverses", ["verse_id"], :name => "index_memverses_on_verse_id"

  create_table "open_id_authentication_associations", :force => true do |t|
    t.integer "issued"
    t.integer "lifetime"
    t.string  "handle"
    t.string  "assoc_type"
    t.binary  "server_url"
    t.binary  "secret"
  end

  create_table "open_id_authentication_nonces", :force => true do |t|
    t.integer "timestamp",  :null => false
    t.string  "server_url"
    t.string  "salt",       :null => false
  end

  create_table "passwords", :force => true do |t|
    t.integer  "user_id"
    t.string   "reset_code"
    t.datetime "expiration_date"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "popverses", :force => true do |t|
    t.string   "pop_ref",    :null => false
    t.integer  "num_users",  :null => false
    t.string   "book",       :null => false
    t.string   "chapter",    :null => false
    t.string   "versenum",   :null => false
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

  create_table "progress_reports", :force => true do |t|
    t.integer "user_id",         :null => false
    t.date    "entry_date"
    t.integer "learning"
    t.integer "memorized"
    t.integer "time_allocation"
  end

  add_index "progress_reports", ["user_id"], :name => "index_progress_reports_on_user_id"

  create_table "quests", :force => true do |t|
    t.integer  "rank"
    t.string   "task"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "quests", ["rank"], :name => "index_quests_on_rank"

  create_table "quests_users", :id => false, :force => true do |t|
    t.integer "quest_id"
    t.integer "user_id"
  end

  create_table "roles", :force => true do |t|
    t.string "name"
  end

  create_table "roles_users", :id => false, :force => true do |t|
    t.integer "role_id"
    t.integer "user_id"
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "taggings", :force => true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.integer  "tagger_id"
    t.string   "tagger_type"
    t.string   "taggable_type"
    t.string   "context"
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"
  add_index "taggings", ["taggable_id", "taggable_type", "context"], :name => "index_taggings_on_taggable_id_and_taggable_type_and_context"

  create_table "tags", :force => true do |t|
    t.string "name"
  end

  create_table "tweets", :force => true do |t|
    t.integer  "importance",        :default => 5
    t.integer  "user_id"
    t.integer  "church_id"
    t.integer  "american_state_id"
    t.integer  "country_id"
    t.string   "news"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "tweets", ["american_state_id"], :name => "index_tweets_on_american_state_id"
  add_index "tweets", ["church_id"], :name => "index_tweets_on_church_id"
  add_index "tweets", ["country_id"], :name => "index_tweets_on_country_id"
  add_index "tweets", ["importance"], :name => "index_tweets_on_importance"
  add_index "tweets", ["user_id"], :name => "index_tweets_on_user_id"

  create_table "users", :force => true do |t|
    t.string   "login",                     :limit => 40
    t.string   "identity_url"
    t.string   "name",                      :limit => 100, :default => ""
    t.string   "email",                     :limit => 100
    t.string   "crypted_password",          :limit => 40
    t.string   "salt",                      :limit => 40
    t.string   "remember_token",            :limit => 40
    t.string   "activation_code",           :limit => 40
    t.string   "state",                                    :default => "passive",  :null => false
    t.datetime "remember_token_expires_at"
    t.datetime "activated_at"
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.date     "last_reminder"
    t.string   "reminder_freq",                            :default => "weekly"
    t.boolean  "newsletters",                              :default => true
    t.string   "church"
    t.integer  "church_id"
    t.integer  "country_id"
    t.string   "language",                                 :default => "English"
    t.integer  "time_allocation",                          :default => 5
    t.integer  "memorized",                                :default => 0
    t.integer  "learning",                                 :default => 0
    t.date     "last_activity_date"
    t.boolean  "show_echo",                                :default => true
    t.integer  "max_interval",                             :default => 366
    t.string   "mnemonic_use",                             :default => "Learning"
    t.integer  "american_state_id"
    t.integer  "accuracy",                                 :default => 50
    t.boolean  "all_refs",                                 :default => true
    t.integer  "rank"
    t.integer  "ref_grade",                                :default => 10
    t.string   "gender"
    t.string   "translation",                              :default => "NIV"
  end

  add_index "users", ["login"], :name => "index_users_on_login", :unique => true

  create_table "verses", :force => true do |t|
    t.string   "translation",                    :null => false
    t.integer  "book_index",                     :null => false
    t.string   "book",                           :null => false
    t.string   "chapter",                        :null => false
    t.string   "versenum",                       :null => false
    t.text     "text"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "verified",    :default => false, :null => false
    t.boolean  "error_flag",  :default => false, :null => false
  end

end
