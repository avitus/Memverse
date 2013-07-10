class AddPopularityToVerses < ActiveRecord::Migration
  def change
    add_column :verses, :popularity, :decimal, :precision => 5, :scale => 2
  end
end
