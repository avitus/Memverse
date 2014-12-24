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
  belongs_to :badge

  # Is task complete?
  # @return [Boolean]
  def complete?(user)
    categories = {'Gospels' => :gospel,
                  'Epistles' => :epistle,
                  'Wisdom' => :wisdom,
                  'History' => :history,
                  'Prophecy' => :prophecy}

    case objective

      # Quest is to be learning or have memorized so many verses from category
      when *categories.keys
        mvs = user.memverses.try(categories[objective])

        if qualifier == 'Learning'
          mvs.length >= quantity
        elsif qualifier == 'Memorized'
          mvs.memorized.length >= quantity
        else
          false
        end

      when 'Verses'
        case qualifier
          when 'Learning'
            user.learning + user.memorized >= quantity
          when 'Memorized'
            user.memorized >= quantity
          else
            false
        end

      when 'Chapters'
        chapters = user.complete_chapters

        case qualifier
          when 'Learning'
            chapters.length >= quantity
          when 'Memorized'
            chapters.select { |ch| ch[0] == "Memorized" }.length >= quantity
          else
            chapters.select { |ch| ch == ["Memorized", qualifier] }.length >= 1
        end

      when 'Books'
        false

      when 'Accuracy'
        user.accuracy >= quantity

      when 'References'
        user.ref_grade >= quantity

      when 'Sessions'
        user.completed_sessions >= quantity

      when 'Annual Sessions'
        user.completed_sessions(:year) >= quantity

      when 'Referrals'
        user.referral_score >= quantity

      when 'Tags'
        user.num_taggings >= quantity

      when 'Url'
        false # Quest is flagged as complete when user visits URL

      else
        false

    end
  end

  # Adds task to list of completed tasks (if not already completed)
  # @return [void]
  def check_quest_off(user)
    if !user.quests.include?(self)  # can only complete a quest once
      user.quests << self
    end
  end

end
