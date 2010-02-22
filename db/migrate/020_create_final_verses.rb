class CreateFinalVerses < ActiveRecord::Migration
  def self.up
  
    # Create Final Verses Table
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
