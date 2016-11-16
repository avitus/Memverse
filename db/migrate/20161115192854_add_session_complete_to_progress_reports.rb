class AddSessionCompleteToProgressReports < ActiveRecord::Migration
  def change
    add_column :progress_reports, :session_complete, :boolean
  end
end
