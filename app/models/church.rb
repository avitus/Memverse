class Church < ActiveRecord::Base

  #  t.string    :name,          :null => false
  #  t.text      :description
  #  t.text      :url   --- not yet implemented
  #  t.integer   :country_id
  #  t.timestamps

  # Relationships
  has_many    :users
  has_many    :tweets
  has_many    :sermons
  belongs_to  :country

  # Validations
  validates_presence_of   :name
  validates_uniqueness_of :name

  # attr_accessible :name, :description

  scope :vibrant, -> { where('users_count >= 3') }

  # Returns hash of top churches (sorted by number of verses memorized).
  # Also creates a Tweet when a church joins the leaderboard or changes position.
  # @param numchurches Max number of churches to return
  # @return [Hash] Top churches with verses memorized
  def self.top_churches(numchurches=70)

    churchboard = Hash.new(0)

    vibrant.find_each { |grp| churchboard[ grp ] = grp.users.active.sum('memorized') }

    churchboard.sort{|a,b| a[1]<=>b[1]}.reverse[0...numchurches].each_with_index { |grp, index|
      if grp[0].rank.nil?
        Tweet.create(news: "#{grp[0].name} joined the church leaderboard at position ##{index+1}", church_id: grp[0].id, importance: 4)
      elsif (index+1 < grp[0].rank) and (grp[0].rank <= 20)
      	importance = [index + 1, 4].min
        Tweet.create(news: "#{grp[0].name} is now ##{index+1} on the church leaderboard", church_id: grp[0].id, importance: importance)
      end
      grp[0].rank = index+1
      grp[0].save
    }

  end


end