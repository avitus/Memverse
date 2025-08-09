class AddSessionCompleteToProgressReports < ActiveRecord::Migration[7.0]
  def change
    add_column :progress_reports, :session_complete, :boolean
  end
end
