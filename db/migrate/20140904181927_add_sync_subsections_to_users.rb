class AddSyncSubsectionsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :sync_subsections, :boolean, :default => false
  end
end
