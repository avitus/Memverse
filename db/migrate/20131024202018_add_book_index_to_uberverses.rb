class AddBookIndexToUberverses < ActiveRecord::Migration
  def change
    add_column :uberverses, :book_index, :integer
    add_index :uberverses, :book_index

    remove_column :uberverses, :created_at, :datetime
    remove_column :uberverses, :updated_at, :datetime
  end
end
