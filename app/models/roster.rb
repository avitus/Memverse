# class Roster < SuperModel::Base
#   include SuperModel::Redis::Model
#   include SuperModel::Timestamp::Model

#   attributes :count, :user_name

#   belongs_to :user
#   validates_presence_of :user_id

#   after_create 'self.publish_roster(:create)'
# #  after_update 'self.publish_roster(:update)' # I don't think we need to publish the roster when a roster record is updated
#   after_destroy 'self.publish_roster(:destroy)'

#   indexes :user_id

#   class << self
#     def for_user(user)
#       # user_ids = user.channels.user_ids
# 	  user_ids = Array.new
#       $redis.keys("roster:user_id:*").each do |user|
#         user_ids << user.gsub("roster:user_id:","").to_i
#       end
#       user_ids.map {|id| find_by_user_id(id) }.compact
#     end

#     def subscribe
#       Juggernaut.subscribe do |event, data|
#         data.default = {}
#         user_id      = data["meta"]["user_id"]
#     		user_name    = data["meta"]["user_name"]
#     		gravatar_url = data["meta"]["gravatar_url"]
#         next unless user_id

#         case event
#           when :subscribe
#             event_subscribe(user_id, user_name, gravatar_url)
#           when :unsubscribe
#             event_unsubscribe(user_id)
#         end
#       end
#     end

#     protected
#       def event_subscribe(user_id, user_name, gravatar_url)
#         user = find_by_user_id(user_id) || self.new(:user_id => user_id, :user_name => user_name, :gravatar_url => gravatar_url)
#         user.increment!
#       end

#       def event_unsubscribe(user_id)
#         user = find_by_user_id(user_id)
#         user && user.decrement!
#       end
#   end

#   def count
#     read_attribute(:count) || 0
#   end

#   def increment!
#     self.count += 1
#     save!
#   end

#   def decrement!
#     self.count -= 1
#     self.count > 0 ? save! : destroy
#   end

#   def observer_clients
#     # user.channels.user_ids
#     user_ids = Array.new
#     $redis.keys("roster:user_id:*").each do |user|
#       user_ids << user.gsub("roster:user_id:","").to_i
#     end
#     return user_ids
#   end

#   def publish_roster(type)
#     Juggernaut.publish("/roster",
#       {
#         :type  => type, :id => self.id,
#         :klass => self.class.name, :record => self
#       })
#   end

#   def as_json(options={})
#     super(:only => [:user_id, :user_name, :gravatar_url])
#   end

# end
