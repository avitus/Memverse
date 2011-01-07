class CreateFinalVerses < ActiveRecord::Migration
  def self.up
    # Create Final Verses Table
    # Fill this table by visiting /admin/get_last_verse_data
    create_table  :final_verses do |t|
      t.string    :book,          :null => false
      t.integer   :chapter,       :null => false
      t.integer   :last_verse,    :null => false
    end     
  end

  def self.down
    drop_table :final_verses
  end
end
