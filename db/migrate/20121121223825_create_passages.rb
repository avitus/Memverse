class CreatePassages < ActiveRecord::Migration
  def change

    # Create Passage table
    create_table :passages do |t|
      t.references :user, :null => false
      t.integer    :length, :null => false, :default => 1

      t.string     :reference
      t.string     :book, :null => false
      t.integer    :chapter, :null => false
      t.integer    :first_verse, :null => false
      t.integer    :last_verse, :null => false

      t.decimal    :efactor
      t.integer    :test_interval
      t.integer    :rep_n
      t.date       :next_test
      t.date       :last_tested

      t.timestamps
    end

    # Add indexes
    add_index :passages, :user_id

    # Add foreign key to Memverse model
    add_column :memverses, :passage_id, :integer

  end
end
