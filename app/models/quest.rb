# t.integer  "level"
# t.string   "task"
# t.text     "description"
# t.string   "objective"
# t.string   "qualifier"
# t.integer  "quantity"
# t.string   "url"
# t.datetime "created_at"
# t.datetime "updated_at"
#
# +-----+-------+-----------------------------------------+-------------+-----------+-----------+----------+-----+-------------------------+-------------------------+
# | id  | level | task                                    | description | objective | qualifier | quantity | url | created_at              | updated_at              |
# +-----+-------+-----------------------------------------+-------------+-----------+-----------+----------+-----+-------------------------+-------------------------+
# | 200 | 16    | Memorize 13 verses of biblical prophecy |             | Prophecy  | Memorized | 13       |     | 2011-01-14 15:31:25 UTC | 2011-01-14 15:32:17 UTC |
# +-----+-------+-----------------------------------------+-------------+-----------+-----------+----------+-----+-------------------------+-------------------------+

class Quest < ActiveRecord::Base
  has_and_belongs_to_many :users

  # ----------------------------------------------------------------------------------------------------------
  # Returns true if a task has been completed
  # ----------------------------------------------------------------------------------------------------------
  def complete?(user)
    case self.objective

      when 'Verses'

        case self.qualifier
          when 'Learning'
            user.learning + user.memorized >= self.quantity
          when 'Memorized'
            user.memorized >= self.quantity
          else
            false
        end

      when 'Gospels'
        case self.qualifier
          when 'Learning'
            user.memverses.gospel.length >= self.quantity
          when 'Memorized'
            user.memverses.gospel.memorized.length >= self.quantity
          else
            false
        end


      when 'Epistles'
        case self.qualifier
          when 'Learning'
            user.memverses.epistle.length >= self.quantity
          when 'Memorized'
            user.memverses.epistle.memorized.length >= self.quantity
          else
            false
        end

      when 'Wisdom'
        case self.qualifier
          when 'Learning'
            user.memverses.wisdom.length >= self.quantity
          when 'Memorized'
            user.memverses.wisdom.memorized.length >= self.quantity
          else
            false
        end

      when 'History'
        case self.qualifier
          when 'Learning'
            user.memverses.history.length >= self.quantity
          when 'Memorized'
            user.memverses.history.memorized.length >= self.quantity
          else
            false
        end

      when 'Prophecy'
        case self.qualifier
          when 'Learning'
            user.memverses.prophecy.length >= self.quantity
          when 'Memorized'
            user.memverses.prophecy.memorized.length >= self.quantity
          else
            false
        end

      when 'Chapters'
        case self.qualifier
          when 'Learning'
            user.complete_chapters.length >= self.quantity
          when 'Memorized'
            user.complete_chapters.select { |ch| ch[0] == "Memorized" }.length >= self.quantity
          else
            user.complete_chapters.select { |ch| ch[0] == "Memorized" && ch[1] == self.qualifier }.length >= 1
        end

      when 'Books'
        false

      when 'Accuracy'
        user.accuracy >= self.quantity

      when 'References'
        user.ref_grade >= self.quantity

      when 'Sessions'
        user.completed_sessions >= self.quantity

      when 'Annual Sessions'
        user.completed_sessions(:year) >= self.quantity

      when 'Referrals'
        user.referral_score >= self.quantity

      when 'Tags'
        user.num_taggings >= self.quantity

      when 'Url'
        false # Quest is flagged as complete when user visits URL

      else
        false

    end
  end

  # ----------------------------------------------------------------------------------------------------------
  # Adds task to list of completed tasks (if not already completed)
  # ----------------------------------------------------------------------------------------------------------
  def check_quest_off(user)
    if !user.quests.include?(self)  # can only complete a quest once
      user.quests << self
    end
  end

end
