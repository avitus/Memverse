# This migration comes from forem (originally 20120221195807)
class AddPendingReviewToForemTopics < ActiveRecord::Migration[7.0]
  def change
    add_column :forem_topics, :pending_review, :boolean, :default => true

    Forem::Topic.reset_column_information
    Forem::Topic.update_all :pending_review => false
  end
end
