# This migration comes from forem (originally 20110626160056)
class AddHiddenToForemTopics < ActiveRecord::Migration[7.0]
  def change
    add_column :forem_topics, :hidden, :boolean, :default => false
  end
end
