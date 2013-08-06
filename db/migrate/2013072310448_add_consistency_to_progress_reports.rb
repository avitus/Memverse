class AddConsistencyToProgressReports < ActiveRecord::Migration
  def up
    add_column :progress_reports, :consistency, :integer
    ProgressReport.reset_column_information
    ProgressReport.all.each {|pr| pr.save! }
  end
  
  def down
    remove_column :progress_reports, :consistency, :integer
  end
end
