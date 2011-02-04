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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20) do

  create_table "american_states", :force => true do |t|
    t.string "abbrev", :limit => 20, :default => "", :null => false
    t.string "name",   :limit => 50, :default => "", :null => false
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

  create_table "countries", :force => true do |t|
    t.string  "iso",            :limit => 2,  :null => false
    t.string  "name",           :limit => 80, :null => false
    t.string  "printable_name", :limit => 80, :null => false
    t.string  "iso3",           :limit => 3
    t.integer "numcode",        :limit => 2
  end

  create_table "final_verses", :force => true do |t|
    t.string  "book",       :null => false
    t.integer "chapter",    :null => false
    t.integer "last_verse", :null => false
  end

end
