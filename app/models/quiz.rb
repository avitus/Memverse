  #    t.integer   :user_id, null: false
  #    t.string    :name
  #    t.text      :description
  #    t.integer   :no_questions, default: "0"

class Quiz < ActiveRecord::Base

  # Relationships
  belongs_to :user
  has_many :quiz_questions

  # Validations
  # validates_presence_of :user_id

  def update_length

    length = 0

    for question in self.quiz_questions

      # Note that 1 is added to each of these because we put a 1 second gap between questions
      case question.question_type

        when "recitation"
          length = length + (question.passage_translations.first.last.split(" ").length * 2.5 + 15.0).to_i + 1 # 24 WPM typing speed with 15 seconds to think

        when "reference"
          length = length + 25 + 1

        when "mcq"
          length = length + 30 + 1
        end

    end

    self.quiz_length = length
  	self.save

  end

  def hours_till_start
    return (start_time - Time.now)/3600
  end

  # ============= Protected below this line ==================================================================
  protected

end
