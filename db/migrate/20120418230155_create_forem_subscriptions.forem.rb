# This migration comes from forem (originally 20111208014437)
class CreateForemSubscriptions < ActiveRecord::Migration[7.0]
  def change
    create_table :forem_subscriptions do |t|
      t.integer :subscriber_id
      t.integer :topic_id
    end
  end
end
