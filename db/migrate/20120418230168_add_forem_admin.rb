class AddForemAdmin < ActiveRecord::Migration[7.0]

  def change
    add_column :users, :forem_admin, :boolean, :default => false
  end
end
