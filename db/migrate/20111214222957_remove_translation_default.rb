class RemoveTranslationDefault < ActiveRecord::Migration
  def up
    change_column_default(:users, :translation, nil)
  end

  def down
    change_column_default(:users, :translation, "NIV")
  end
end
