class ProgressReport < ActiveRecord::Base

  # ----------------------------------------------------------------------------------------------------------
  # Swagger-Blocks DSL [START]
  # ----------------------------------------------------------------------------------------------------------
  include Swagger::Blocks

  swagger_schema :ProgressReport do
    key :required, [:user_id, :entry_date, :learning, :memorized, :time_allocation, :consistency]
    property :user_id do
      key :type, :integer
      key :format, :int64
    end
    property :entry_date do
      key :type, :string
      key :format, :date
    end 
    property :learning do
      key :type, :integer
      key :format, :int64
    end
    property :memorized do
      key :type, :integer
      key :format, :int64
    end  
    property :time_allocation do
      key :type, :integer
      key :format, :int64
    end  
    property :consistency do
      key :type, :integer
      key :format, :int64
    end           
  end
  # ----------------------------------------------------------------------------------------------------------
  # Swagger-Blocks DSL [END]
  # ----------------------------------------------------------------------------------------------------------

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
    self.consistency = user.progress_reports.where(entry_date: (entry_date - 1.year + 1)..entry_date).count
  end
  
end