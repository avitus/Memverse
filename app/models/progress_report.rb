class ProgressReport < ActiveRecord::Base

  # Structure
  #  t.integer   :user_id,     :null => false
  #  t.date      :entry_date
  #  t.integer   :learning      
  #  t.integer   :memorized
  #  t.integer   :time_allocation


  # Relationships
  belongs_to  :user
  
  # Validations
  validates_presence_of :user_id, :learning, :memorized, :entry_date
  after_save :setup_consistency 

  protected
  
  def setup_consistency
    self.consistency = ProgressReport.where('entry_date > ? and entry_date <= ?', entry_date - 1.year, entry_date).count
  end
  
end