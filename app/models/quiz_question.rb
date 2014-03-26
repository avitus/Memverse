  #    t.integer   :quiz_id, :null => false
  #    t.integer   :variation_id
  #    t.integer   :question_no
  #    t.string    :question_type
  #    t.text      :text
  #    t.text      :correct_answer
  #    t.integer   :time

class QuizQuestion < ActiveRecord::Base

  include Parser

  # Relationships
  belongs_to :quiz
  belongs_to :user,           :foreign_key => "submitted_by",   :class_name => "User"
  belongs_to :supporting_ref, :foreign_key => "supporting_ref", :class_name => "Uberverse"

  # Query scopes
  scope :mcq,         -> { where( :question_type   => "mcq"                 ) }
  scope :recitation,  -> { where( :question_type   => "recitation"          ) }
  scope :reference,   -> { where( :question_type   => "reference"           ) }

  scope :fresh,       -> { where( 'last_asked < ?', Date.today - 6.months   ) }
  scope :approved,    -> { where( :approval_status => "Approved"            ) }
  scope :pending,     -> { where( :approval_status => "Pending"             ) }
  scope :rejected,    -> { where( :approval_status => "Rejected"            ) }

  scope :easy,        -> { where( :perc_correct    => 66..100               ) }
  scope :medium,      -> { where( :perc_correct    => 34..65                ) }
  scope :hard,        -> { where( :perc_correct    =>  0..33                ) }

  # Validations
  # validates_presence_of :user_id

  after_create  'self.quiz.update_length'
  after_update  'self.quiz.update_length'
  after_destroy 'self.quiz.update_length'

  def passage_translations

    passages = Hash.new
    quiz_translations = ["NAS", "NKJ", "KJV", "ESV"] # MAJORS.keys.collect { |k| k.to_s }
    # NOTE: If this is changed, update live_quiz message about choosing a version to reflect

    error_flag, bk, ch, vs_start, vs_end = parse_passage(self.passage)
    if error_flag
      return nil
    else
      if vs_end
        verse_variations = Verse.where(:book => bk, :chapter => ch, :versenum => (vs_start..vs_end).to_a, :translation => quiz_translations).order("versenum ASC")
      else
        verse_variations = Verse.where(:book => bk, :chapter => ch, :versenum => vs_start, :translation => quiz_translations).order("versenum ASC")
      end

      quiz_translations.each { |tl|
        verses_for_single_translation = verse_variations.select { |vs| vs.translation == tl }
        verse_texts = verses_for_single_translation.collect { |vs| vs.text }
        passages[tl] = verse_texts.join(" ")
      }

      return passages

    end

  end

  # ----------------------------------------------------------------------------------------------------------
  # Update difficulty of quiz question based on number of users getting question correct
  # ----------------------------------------------------------------------------------------------------------
  def update_difficulty( answer_count, percentage_correct )
    new_total_answers   = answer_count + self.times_answered
    self.perc_correct   = ((answer_count * percentage_correct ) + (self.times_answered * self.perc_correct )) / new_total_answers
    self.times_answered = new_total_answers
    self.save
  end

  # ----------------------------------------------------------------------------------------------------------
  # Estimate time required (in seconds) for question
  # ----------------------------------------------------------------------------------------------------------
  def time_allocation
    case self.question_type
      when 'mcq'
        reading_required = [ mc_question, mc_option_a, mc_option_b, mc_option_c, mc_option_d ].join(" ")
        ( reading_required.split(" ").length * 0.5 ).to_i + 7  # 0.5 second for each word + 7 seconds
      when 'recitation'
        ( self.passage_translations.first.last.split(" ").length * 2.5 + 15.0 ).to_i # 24 WPM typing speed with 15 seconds to think
      when 'reference'
        25
    end
  end

  # ----------------------------------------------------------------------------------------------------------
  # Related Quiz Questions (that share the same supporting reference)
  # TODO: would be nice to expand with a clever search by keyword in the question text
  # ----------------------------------------------------------------------------------------------------------
  def related_questions
    if self.supporting_ref
      return self.supporting_ref.quiz_questions.where("id != ?", self.id)
    else
      return []
    end
  end

  # ----------------------------------------------------------------------------------------------------------
  # Related Quiz Questions (that share the same supporting reference)
  # TODO: would be nice to expand with a clever search by keyword in the question text
  # ----------------------------------------------------------------------------------------------------------
  def supporting_verses
    if self.supporting_ref
      return self.supporting_ref.verses.where(:translation => ['NIV', 'ESV', 'NAS', 'NKJ', 'KJV'])
    else
      return []
    end
  end

  def is_approved?
    return self.approval_status == "Approved"
  end


  # ============= Protected below this line ==================================================================
  protected

end
