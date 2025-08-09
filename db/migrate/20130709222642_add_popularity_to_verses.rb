class AddPopularityToVerses < ActiveRecord::Migration[7.0]
  def change
    add_column :verses, :popularity, :decimal, :precision => 5, :scale => 2
  end
end
