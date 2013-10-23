class AddDetailsToQuizQuestions < ActiveRecord::Migration
  def change

    add_column :quiz_questions, :times_answered, :integer, :default => 0
    add_column :quiz_questions, :perc_correct,   :decimal, :default => 50  # default to medium difficulty
    add_column :quiz_questions, :mcq_category,   :string,  index: true
    add_column :quiz_questions, :last_asked,     :date,    :default => Date.today - 1.year

    # Foreign key for Uberverse model
    add_column :quiz_questions, :supporting_ref, :integer, index: true

    # Foreign key for User model
    add_column :quiz_questions, :submitted_by,   :integer, index: true

  end
end
