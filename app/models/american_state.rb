class AmericanState < ActiveRecord::Base

#    t.string  "abbrev",      :limit => 20, :default => "", :null => false
#    t.string  "name",        :limit => 50, :default => "", :null => false
#    t.integer "users_count",               :default => 0
#    t.integer "population"

  # Relationships
  has_many :users
  has_many :tweets

  # Validations
  validates_presence_of :name, :abbrev

  scope :vibrant, -> { where('users_count >= 3') }

  extend FriendlyId
  friendly_id :name, use: :slugged

  # ----------------------------------------------------------------------------------------------------------
  # Returns hash of top countries (sorted by number of verses memorized)
  # ----------------------------------------------------------------------------------------------------------
  def self.top_states(numstates = 50)

    stateboard = Hash.new(0)

    vibrant.find_each { |grp| stateboard[ grp ] = grp.users.active.sum('memorized') }

    stateboard.sort{|a,b| a[1]<=>b[1]}.reverse[0...numstates].each_with_index { |grp, index|
      if grp[0].rank.nil?
        Tweet.create(:news => "#{grp[0].name} joined the state leaderboard at position ##{index+1}", :american_state_id => grp[0].id, :importance => 4)
      elsif (index+1 < grp[0].rank) and (grp[0].rank <= 20)
      	importance = [index + 1, 4].min
        Tweet.create(:news => "#{grp[0].name} is now ##{index+1} on the state leaderboard", :american_state_id => grp[0].id, :importance => importance)
      end
      grp[0].rank = index+1
      grp[0].save
    }

  end



end