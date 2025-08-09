class AddReviewedToProgressReports < ActiveRecord::Migration[7.0]
  def change
    add_column :progress_reports, :reviewed, :integer
  end
end
