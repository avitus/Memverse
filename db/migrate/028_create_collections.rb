class CreateCollections < ActiveRecord::Migration
  def self.up
    create_table :collections do |t|
      t.string      :name
      t.references  :user,        :null => false
      t.string      :translation, :null => false
      t.timestamps
    end
  end

  def self.down
    drop_table :collections
  end
end

