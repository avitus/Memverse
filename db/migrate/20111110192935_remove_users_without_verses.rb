class RemoveUsersWithoutVerses < ActiveRecord::Migration[7.0]
  def up
    User.where("login != ? and created_at < ? and learning = ? and memorized = ?",'admin', 7.days.ago, 0, 0).delete_all
  end

  def down
  end
end
