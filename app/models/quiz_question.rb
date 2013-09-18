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
  has_many :quiz_answers, :through => :livequizzes  # TODO: What does this refer to?

  # Validations
  # validates_presence_of :user_id

  after_create 'self.quiz.update_length'
  after_update 'self.quiz.update_length'
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

  # ============= Protected below this line ==================================================================
  protected

end
