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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130213224102) do

  create_table "cars", :force => true do |t|
    t.string "model"
  end

  create_table "users", :force => true do |t|
    t.string   "name"
    t.string   "last_name"
    t.string   "address"
    t.string   "email",           :null => false
    t.string   "zip"
    t.string   "country"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
    t.boolean  "receive_email"
    t.text     "description"
    t.string   "favorite_color"
    t.text     "favorite_books"
    t.datetime "birth_date"
    t.float    "money"
    t.float    "money_proc"
    t.string   "height"
    t.string   "favorite_movie"
    t.string   "favorite_locale"
  end

end
