# This migration comes from acts_as_taggable_on_engine (originally 2)

# ALV: This migration results in terrible performance on tag_list queries. Don't use for now.
# Use the following queries in irb to find duplicate tags and taggings. Do this before running migration.
#
# ActsAsTaggableOn::Tagging.select("id, count(id) as quantity").group([:tagger_id, :tag_id, :taggable_id, :context, :tagger_type]).having("quantity > 1")
# ActsAsTaggableOn::Tag.select("id, count(id) as quantity").group(:name).having("quantity > 1")
#

class AddMissingUniqueIndices < ActiveRecord::Migration

  # def self.up
  #   add_index :tags, :name, unique: true

  #   remove_index :taggings, :tag_id
  #   remove_index :taggings, [:taggable_id, :taggable_type, :context]
  #   add_index :taggings,
  #     [:tag_id, :taggable_id, :taggable_type, :context, :tagger_id, :tagger_type],
  #     unique: true, name: 'taggings_idx'
  #  end

  # def self.down
  #   remove_index :tags, :name

  #   remove_index :taggings, name: 'taggings_idx'
  #   add_index :taggings, :tag_id
  #   add_index :taggings, [:taggable_id, :taggable_type, :context]
  # end

end
