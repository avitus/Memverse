class AddConsistencyToProgressReports < ActiveRecord::Migration
  def change
    add_column :progress_reports, :consistency, :integer
    ProgressReport.before_save :setup_consistency
    ProgressReport.reset_column_information
    ProgressReport.all.each.do |pr|
      pr.save  
  end
end
