class Country < ActiveRecord::Base

  #  t.string    :name            VARCHAR(80) :null => false
  #  t.string    :printable_name  VARCHAR(80) :null => false
  #  t.string    :iso3            CHAR(3)
  #  t.string    :numcode         SMALLINT

  # Relationships
  has_many :users
  has_many :churches
  has_many :tweets


  # Validations
  validates_presence_of :name, :printable_name

  scope :vibrant, -> { where('users_count >= 3') }

  extend FriendlyId
  friendly_id :printable_name, use: :slugged

  # Hash of top countries (sorted by number of verses memorized)
  # @return [Hash] Country name and verses memorized
  def self.top_countries(numcountries=25)
    countryboard = Hash.new(0)

    vibrant.find_each { |grp| countryboard[ grp ] = grp.users.active.sum('memorized') }

    countryboard.sort{|a,b| a[1]<=>b[1]}.reverse[0...numcountries].each_with_index { |grp, index|
      if grp[0].rank.nil?
        Tweet.create(:news => "#{grp[0].printable_name} joined the country leaderboard at position ##{index+1}", :country_id => grp[0].id, :importance => 4)
      elsif (index+1 < grp[0].rank)
      	importance = [index + 1, 4].min
        Tweet.create(:news => "#{grp[0].printable_name} is now ##{index+1} on the country leaderboard", :country_id => grp[0].id, :importance => importance)
      end
      grp[0].rank = index+1
      grp[0].save
    }
  end

end