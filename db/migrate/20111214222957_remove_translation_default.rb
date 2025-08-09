class RemoveTranslationDefault < ActiveRecord::Migration[7.0]
  def up
    change_column_default(:users, :translation, nil)
  end

  def down
    change_column_default(:users, :translation, "NIV")
  end
end
