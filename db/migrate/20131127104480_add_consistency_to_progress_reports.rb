class AddConsistencyToProgressReports < ActiveRecord::Migration

  # ================================================================================================
  # This migration is commented out since for some reason it was run out of sequence and now Rails
  # wants to run it every time
  # ================================================================================================

  # def up
  #   add_column :progress_reports, :consistency, :integer
  #   ProgressReport.reset_column_information
  #   ProgressReport.find_each {|pr| pr.save! }
  # end

  # def down
  #   remove_column :progress_reports, :consistency, :integer
  # end
end
