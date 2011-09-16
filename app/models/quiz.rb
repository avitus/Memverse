  #    t.integer   :user_id, :null => false
  #    t.string    :name
  #    t.text      :description
  #    t.integer   :no_questions, :default => "0"

class Quiz < ActiveRecord::Base
    
  # Relationships
  belongs_to :user
  has_many :quiz_questions
    
  # Validations
  # validates_presence_of :user_id

  

  # ============= Protected below this line ==================================================================
  protected
  
end
