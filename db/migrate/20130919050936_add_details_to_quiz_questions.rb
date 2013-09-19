class AddDetailsToQuizQuestions < ActiveRecord::Migration
  def change
    
    add_column :quiz_questions, :times_answered, :integer
    add_column :quiz_questions, :perc_correct,   :decimal
    add_column :quiz_questions, :mcq_category,   :string,  index: true

    # Foreign key for Uberverse model
    add_column :quiz_questions, :supporting_ref, :integer, index: true
    
    # Foreign key for User model
    add_column :quiz_questions, :submitted_by,   :integer, index: true

  end
end
