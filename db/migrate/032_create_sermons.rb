class CreateSermons < ActiveRecord::Migration
  def self.up
    create_table :sermons do |t|
      t.string   :title
      t.text     :summary
      t.integer  :church_id
      t.integer  :pastor_id
      t.integer  :user_id
      t.integer  :uberverse_id
      t.string   :mp3_file_name
      t.string   :mp3_content_type
      t.integer  :mp3_file_size
      t.datetime :mp3_updated_at
      t.timestamps
    end
         
    create_table :pastors do |t|
      t.string :name
      t.timestamps
    end
      
    create_table :uberverses do |t|
      t.string  :book,       :null => false
      t.integer :chapter,   :null => false
      t.integer :versenum,  :null => false
      t.timestamps
    end
    
    add_index :sermons,     :title
    add_index :sermons,     :church_id 
    add_index :sermons,     :pastor_id
    add_index :sermons,     :user_id
    add_index :sermons,     :uberverse_id

    add_index :pastors,     :name
    
    add_index :uberverses,  :book
    add_index :uberverses,  :chapter
    add_index :uberverses,  :versenum
    
    add_column :verses,     :uberverse_id, :integer
    add_column :memverses,  :uberverse_id, :integer
    
    
    create_table :uberverses_sermons, :id => false do |t|
      t.belongs_to :uberverse
      t.belongs_to :sermon
      t.boolean    :primary_verse, :default => false
    end        
  end

  def self.down
    drop_table :sermons
    drop_table :pastors    
    drop_table :uberverses
    drop_table :uberverses_sermons
    
    remove_column :verses,    :uberverse_id
    remove_column :memverses, :uberverse_id
  end
end

