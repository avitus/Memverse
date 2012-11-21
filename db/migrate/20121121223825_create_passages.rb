class CreatePassages < ActiveRecord::Migration
  def change

    # Create Passage table
    create_table :passages do |t|
      t.references :user
      t.integer    :length
      t.string     :reference
      t.decimal    :efactor
      t.integer    :test_interval
      t.integer    :rep_n
      t.date       :next_test
      t.date       :last_tested
      t.integer    :first_verse

      t.timestamps
    end

    # Add indexes
    add_index :passages, :user_id

    # Add foreign key to Memverse model
    add_column :memverses, :passage_id, :integer

  end
end
