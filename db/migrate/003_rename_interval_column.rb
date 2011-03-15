class RenameIntervalColumn < ActiveRecord::Migration
  def self.up
    # RenameColumn
    rename_column "memverses", "interval", "test_interval" 
  end

  def self.down
    rename_column "memverses", "test_interval", "interval"
  end
end