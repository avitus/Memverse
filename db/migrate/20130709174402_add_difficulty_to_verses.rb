class AddDifficultyToVerses < ActiveRecord::Migration[7.0]
  def change
    add_column :verses, :difficulty, :decimal, :precision => 5, :scale => 2
  end
end
