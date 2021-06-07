# frozen_string_literal: true

# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20_180_815_115_856) do
  create_table 'items', force: :cascade do |t|
    t.string 'label'
    t.integer 'position'
    t.integer 'list_id'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['list_id'], name: 'index_items_on_list_id'
  end

  create_table 'lists', force: :cascade do |t|
    t.string 'name'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
  end

  create_table 'people', force: :cascade do |t|
    t.string 'name'
    t.string 'status'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
  end

  create_table 'people_people', force: :cascade do |t|
    t.integer 'contact_id', null: false
    t.integer 'person_id', null: false
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
  end

  create_table 'posts', force: :cascade do |t|
    t.string 'title'
    t.text 'body'
    t.integer 'author_id'
    t.integer 'person_id'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['author_id'], name: 'index_posts_on_author_id'
    t.index ['person_id'], name: 'index_posts_on_person_id'
  end
end
