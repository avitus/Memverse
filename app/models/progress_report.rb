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
  
  def capture_consistency
    # self.consistency = ProgressReport.where(:user_id => user_id).where('entry_date > ? and entry_date < ?', entry_date - 1.year, entry_date + 1).count
    self.consistency = ProgressReport.where(:user_id => user_id).where(:entry_date => (entry_date - 1.year)..(entry_date + 1)).count
  end
  
end