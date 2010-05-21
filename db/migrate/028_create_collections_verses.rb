class CreateCollectionsVerses< ActiveRecord::Migration
  def self.up
      create_table :collections_verses, :id => false do |t|
        t.references :collection
        t.references :verse
        t.timestamps
      end
    end

    def self.down
      drop_table :collections_verses
  end
end