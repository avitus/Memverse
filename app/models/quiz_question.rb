  #    t.integer  :quiz_id,          null: false
  #    t.integer  :question_no
  #    t.string   :question_type
  #    t.string   :passage
  #    t.text     :mc_question
  #    t.string   :mc_option_a
  #    t.string   :mc_option_b
  #    t.string   :mc_option_c
  #    t.string   :mc_option_d
  #    t.string   :mc_answer
  #    t.integer  :times_answered,  default: 0
  #    t.decimal  :perc_correct,    precision: 10, scale: 0, default: 50
  #    t.string   :mcq_category:
  #    t.date     :last_asked,      default: '2013-02-23'
  #    t.integer  :supporting_ref
  #    t.integer  :submitted_by
  #    t.string   :approval_status, default: "Pending"
  #    t.string   :rejection_code
  #    t.datetime :created_at
  #    t.datetime :updated_at

class QuizQuestion < ApplicationRecord

  include Parser

  # Relationships
  belongs_to :quiz
  belongs_to :user,           :foreign_key => "submitted_by",   :class_name => "User", optional: true
  belongs_to :supporting_ref, :foreign_key => "supporting_ref", :class_name => "Uberverse", optional: true

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

  # Longest answer worth grading; keeps the word comparison cheap
  MAX_ANSWER_LENGTH = 5000

  # Validations
  # validates_presence_of :user_id
  validates_presence_of :quiz_id

  # Validate length of MC options
  mc_val = {length: {minimum: 1, maximum: 120}, allow_blank: false, if: :mcq?}
  validates :mc_option_a, mc_val
  validates :mc_option_b, mc_val
  validates :mc_option_c, mc_val
  validates :mc_option_d, mc_val

  # Validate length of MC question
  validates :mc_question, length: {minimum: 8, maximum: 300}, allow_blank: false, if: :mcq?
  # Check that correct answer has been flagged for MCQ questions
  validates :mc_answer, length: {is: 1}, allow_blank: false, if: :mcq?

  ## Validate presence of supporting_ref for reference and recitation questions
  validates :supporting_ref, presence: true, if: :reference?
  validates :supporting_ref, presence: true, if: :recitation?

  after_create  { |quiz_question| quiz_question.quiz.update_length }
  after_update  { |quiz_question| quiz_question.quiz.update_length }
  after_destroy { |quiz_question| quiz_question.quiz.update_length }

  # @return [Hash] Hash with passage text for each major translation
  def passage_translations

    passages = Hash.new
    quiz_translations = ["NAS", "NKJ", "KJV", "ESV", "NIV", "NNV"] # MAJORS.keys.collect { |k| k.to_s }
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

  # Points for an answer given during a live quiz
  # @param answer [String] What the user submitted
  # @param translation [String] Translation of the user, used to grade a recitation
  # @return [Integer] Score out of 10
  def grade_answer(answer, translation: nil)
    answer = answer.to_s.first(MAX_ANSWER_LENGTH)

    case question_type
    when 'mcq'        then grade_mcq_answer(answer)
    when 'reference'  then grade_reference_answer(answer)
    when 'recitation' then grade_recitation_answer(answer, translation)
    else 0
    end
  end

  # Update difficulty of quiz question based on number of users getting question correct
  # @param answer_count [Integer] Number of times question answered during quiz
  # @param percentage_correct
  def update_difficulty( answer_count, percentage_correct )
    return if answer_count.zero?

    new_total_answers   = answer_count + self.times_answered
    self.perc_correct   = ((answer_count * percentage_correct ) + (self.times_answered * self.perc_correct )) / new_total_answers
    self.times_answered = new_total_answers
    self.save
  end

  # Time allocated for question (KnowledgeQuiz)
  # * Multiple choice: 0.4 seconds per word + 10 seconds
  # * Recitation: 2.5 seconds per word (24 WPM) + 15 seconds
  # * Reference: 25 seconds
  # @return [Integer]
  def time_allocation
    case self.question_type
      when 'mcq'
        reading_required = [ mc_question, mc_option_a, mc_option_b, mc_option_c, mc_option_d ].join(" ")
        ( reading_required.split(" ").length * 0.4 ).to_i + 10  # 0.4 second for each word + 10 seconds
      when 'recitation'
        # 24 WPM typing speed with 15 seconds to think
        ( self.passage_translations.first.last.split(" ").length * 2.5 + 15.0 ).to_i
      when 'reference'
        25
    end
  end

  # Related Quiz Questions (that share the same supporting reference)
  # @todo Would be nice to expand with a clever search by keyword in the question text
  def related_questions
    if self.supporting_ref
      return self.supporting_ref.quiz_questions.where("id != ?", self.id)
    else
      return []
    end
  end

  # Related Quiz Questions (that share the same supporting reference)
  # @todo Would be nice to expand with a clever search by keyword in the question text
  def supporting_verses
    if self.supporting_ref
      return self.supporting_ref.verses.where(:translation => ['NIV', 'ESV', 'NAS', 'NKJ', 'KJV'])
    else
      return []
    end
  end

  # Is quiz question approved?
  # @return [Boolean]
  def is_approved?
    return self.approval_status == "Approved"
  end

  # Time allocated for question (ScheduledQuiz)
  # * Multiple choice: 30 seconds
  # * Recitation: 2.5 seconds per word (24 WPM) + 15 seconds
  # * Reference: 25 seconds
  # * Other: 20 seconds
  # @return [Integer]
  def time_alloc
    case self.question_type
    when "recitation"
       # 24 WPM typing speed with 15 seconds to think
      (self.passage_translations.first.last.split.length * 2.5 + 15.0).to_i
    when "reference"
      25
    when "mcq"
      30
    else
      20
    end
  end

  # Push quiz question to quiz channel (PubNub)
  def push_to_channel
    message = {
      meta:       "question",
      q_num:      self.question_no,
      q_type:     self.question_type,
      time_alloc: self.time_alloc
    }

    if question_type == "recitation" || question_type == "reference"
      message[:q_ref]       = self.passage
      message[:q_passages]  = self.passage_translations
    elsif question_type == "mcq"
      for mc_part in [:question, :option_a, :option_b, :option_c, :option_d, :answer]
        # message[:mc_question] = self.mc_question ... etc.
        message["mc_#{mc_part}".to_sym] = self.send("mc_#{mc_part}")
      end
    else
      return false
    end

    PN.publish(
      channel:   self.quiz.channel,
      message:   message,
      http_sync: true,
      callback:  PN_CALLBACK
    )
  end

  # Check if mcq
  # @return [Boolean]
  def mcq?
    question_type == "mcq"
  end

  # Check if reference
  # @return [Boolean]
  def reference?
    question_type == "reference"
  end

  # Check if recitation
  # @return [Boolean]
  def recitation?
    question_type == "recitation"
  end

  # ============= Protected below this line ==================================================================
  protected

  # ============= Private below this line ====================================================================
  private

  # All or nothing, ignoring case
  def grade_mcq_answer(answer)
    answer.strip.casecmp?(mc_answer.to_s.strip) ? 10 : 0
  end

  # 2 points for the book, 3 for the chapter and 5 for the verse
  def grade_reference_answer(answer)
    given   = reference_parts(answer)
    correct = reference_parts(passage)
    return 0 unless given && correct

    points = 0
    points += 2 if given[:book] == correct[:book]
    points += 3 if given[:chapter] == correct[:chapter]
    points += 5 if given[:verse] == correct[:verse]
    points
  end

  # @return [Hash, nil] Book, chapter and verse, or nil if the text is not a reference
  def reference_parts(text)
    normalized = text.to_s.downcase.gsub(/[[:space:]]+/, ' ').strip.sub('psalm ', 'psalms ')
    colon      = normalized.index(':')
    last_space = normalized.rindex(' ')
    return nil unless colon && last_space && last_space < colon

    book    = normalized[0...last_space]
    chapter = normalized[(last_space + 1)...colon]
    verse   = normalized[(colon + 1)..]
    return nil if [book, chapter, verse].any?(&:blank?)

    { book: book, chapter: chapter, verse: verse }
  end

  # 10 points, less one for each word that differs from the verse
  def grade_recitation_answer(answer, translation)
    given   = recitation_words(answer)
    correct = recitation_words(passage_translations.to_h[translation])
    return 0 if given.empty? || correct.empty?

    [10 - word_distance(correct, given), 0].max
  end

  def recitation_words(text)
    text.to_s.downcase.gsub(/[[:space:]]+/, ' ').gsub(/[^a-z ]|\s-|\s—/, '').split
  end

  # Levenshtein distance counted in words
  def word_distance(first, second)
    previous = (0..second.length).to_a

    first.each_with_index do |first_word, first_index|
      current = [first_index + 1]
      second.each_with_index do |second_word, second_index|
        substitution = previous[second_index] + (first_word == second_word ? 0 : 1)
        current << [previous[second_index + 1] + 1, current[second_index] + 1, substitution].min
      end
      previous = current
    end

    previous.last
  end

end
