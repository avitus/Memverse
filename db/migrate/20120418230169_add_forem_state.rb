class AddForemState < ActiveRecord::Migration[7.0]

  def change
    add_column :users, :forem_state, :string, :default => 'pending_review'
  end
end
