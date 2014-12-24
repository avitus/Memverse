class ProgressReport < ActiveRecord::Base

  #  Structure
  #  t.integer   :user_id,     :null => false
  #  t.date      :entry_date
  #  t.integer   :learning      
  #  t.integer   :memorized
  #  t.integer   :time_allocation
  #  t.integer   :consistency

  # Relationships
  belongs_to  :user
  
  # Validations
  validates_presence_of :user_id, :learning, :memorized, :entry_date
  before_save :capture_consistency 

  protected
  
  # Compute consistency [trigger: before_save]
  # This counts the number of sessions the user has completed over the past year.
  # Max of 366 (leap year).
  # @return [void]
  def capture_consistency
    # Need to add 1 to consistency count because current progress report hasn't yet been saved
    self.consistency = user.progress_reports.where(entry_date: (entry_date - 1.year + 1)..entry_date).count + 1
  end
  
end