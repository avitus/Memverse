class AddReviewedToProgressReports < ActiveRecord::Migration
  def change
    add_column :progress_reports, :reviewed, :integer
  end
end
