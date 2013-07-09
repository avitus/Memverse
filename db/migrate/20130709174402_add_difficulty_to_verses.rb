class AddDifficultyToVerses < ActiveRecord::Migration
  def change
    add_column :verses, :difficulty, :decimal, :precision => 5, :scale => 2
  end
end
