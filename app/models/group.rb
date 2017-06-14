class Group < ActiveRecord::Base

  #  t.string    :name,          :null => false
  #  t.text      :description
  #  t.text      :url   --- not yet implemented
  #  t.integer   :country_id
  #  t.timestamps

  # Relationships
  has_many    :users
  has_many    :tweets

  belongs_to :leader, :foreign_key => "leader_id", :class_name => "User"

  # Validations
  validates_presence_of   :name
  validates_uniqueness_of :name

  # attr_accessible :name, :description, :leader_id

  scope :vibrant, -> { where('users_count >= 3') }

  # Top groups, sorted by number of verses memorized
  #
  # @param numgroups [Fixnum]
  # @return [Array<Group>]
  def self.top_groups(numgroups=70)

    groupboard = Hash.new(0)

    vibrant.find_each { |grp| groupboard[ grp ] = grp.users.active.sum('memorized') }

    groupboard.sort{|a,b| a[1]<=>b[1]}.reverse[0...numgroups].each_with_index { |grp, index|
      if grp[0].rank.nil?
        Tweet.create(:news => "#{grp[0].name} joined the group leaderboard at position ##{index+1}", :group_id => grp[0].id, :importance => 4)
      elsif (index+1 < grp[0].rank) and (grp[0].rank <= 20)
      	importance = [index + 1, 4].min
        Tweet.create(:news => "#{grp[0].name} is now ##{index+1} on the group leaderboard", :group_id => grp[0].id, :importance => importance)
      end
      grp[0].rank = index+1
      grp[0].save
    }
  end

  # Group leader
  #
  # Initially the group leader will be whoever created the group.
  # If the group leader becomes inactive, the new leader will be whoever has completed the most memorization
  # sessions and is a member of the group at the time
  #
  # @return [User] group leader
  def get_leader!
    if self.leader.try(:is_active?)
      return self.leader
    else
      self.leader = users.active.sort_by { |u| u.completed_sessions }.last
      save! # TODO: this does not save the new leader ... no idea why
      return self.leader
    end
  end

end
