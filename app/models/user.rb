# t.string   "login",                     :limit => 40
# t.string   "identity_url"
# t.string   "name",                      :limit => 100, :default => ""
# t.string   "email",                     :limit => 100
# t.string   "crypted_password",          :limit => 40
# t.string   "salt",                      :limit => 40
# t.string   "remember_token",            :limit => 40
# t.string   "activation_code",           :limit => 40
# t.string   "state",                     :default => "passive",  :null => false
# t.datetime "remember_token_expires_at"
# t.datetime "activated_at"
# t.datetime "deleted_at"
# t.datetime "created_at"
# t.datetime "updated_at"
# t.date     "last_reminder"
# t.string   "reminder_freq",                            :default => "weekly"
# t.boolean  "newsletters",                              :default => true
# t.string   "church"
# t.integer  "church_id"
# t.integer  "country_id"
# t.string   "language",                                 :default => "English"
# t.integer  "time_allocation",                          :default => 5
# t.integer  "memorized",                                :default => 0
# t.integer  "learning",                                 :default => 0
# t.date     "last_activity_date"
# t.boolean  "show_echo",                                :default => true
# t.integer  "max_interval",                             :default => 366
# t.string   "mnemonic_use",                             :default => "Learning"
# t.integer  "american_state_id"
# t.integer  "accuracy",                                 :default => 10
# t.boolean  "all_refs",                                 :default => true
# t.integer  "rank"
# t.integer  "ref_grade",                                :default => 10
# t.string   "gender"
# t.string   "translation",                              :default => "NIV"
# t.integer  "level",                                    :default => 0,          :null => false
# t.integer  "referred_by"
# t.boolean  "show_email",                               :default => false
# t.boolean  "auto_work_load",                           :default => true

require 'digest/sha1'
require 'digest/md5' # required for Gravatar support in Bloggity

class User < ActiveRecord::Base

  # ----------------------------------------------------------------------------------------------------------
  # Swagger-Blocks DSL [START]
  # ----------------------------------------------------------------------------------------------------------
  include Swagger::Blocks

  swagger_schema :User do
    key :required, [:id, :login, :email]
    property :id do
      key :type, :integer
      key :format, :int64
    end
    property :login do
      key :type, :string
    end 
    property :identity_url do
      key :type, :string
    end 
    property :name do
      key :type, :string
    end 
    property :email do
      key :type, :string
    end 
    property :remember_token_expires_at do
      key :type, :string
    end
    property :deleted_at do
      key :type, :string
      key :format, :dateTime
    end     
    property :created_at do
      key :type, :string
      key :format, :dateTime
    end 
    property :updated_at do
      key :type, :string
      key :format, :dateTime
    end 
    property :last_reminder do
      key :type, :string
      key :format, :date
    end  
    property :reminder_freq do
      key :type, :string
    end  
    property :newsletters do
      key :type, :boolean
    end   
    property :church_id do
      key :type, :integer
      key :format, :int64
    end 
    property :country_id do
      key :type, :integer
      key :format, :int64
    end 
    property :language do
      key :type, :string
    end  
    property :time_allocation do
      key :type, :integer
      key :format, :int64
    end
    property :memorized do
      key :type, :integer
      key :format, :int64
    end
    property :learning do
      key :type, :integer
      key :format, :int64
    end  
    property :last_activity_date do
      key :type, :string
      key :format, :date
    end 
    property :show_echo do
      key :type, :boolean
    end 
    property :max_interval do
      key :type, :integer
      key :format, :int64
    end 
    property :mnemonic_use do
      key :type, :string
      key :format, :date
    end 
    property :american_state_id do
      key :type, :integer
      key :format, :int64
    end 
    property :accuracy do
      key :type, :integer
      key :format, :int64
    end
    property :all_refs do
      key :type, :boolean
    end
    property :rank do
      key :type, :integer
      key :format, :int64
    end 
      property :ref_grade do
      key :type, :integer
      key :format, :int64
    end
    property :gender do
      key :type, :string
    end
    property :translation do
      key :type, :string
    end
    property :level do
      key :type, :integer
      key :format, :int64
    end   
    property :referred_by do
      key :type, :integer
      key :format, :int64
    end
    property :show_email do
      key :type, :boolean
    end
    property :auto_work_load do
      key :type, :boolean
    end
    property :admin do
      key :type, :boolean
    end
    property :group_id do
      key :type, :integer
      key :format, :int64
    end 
    property :forem_admin do
      key :type, :boolean
    end
    property :forem_state do
      key :type, :string
    end
    property :forem_auto_subscribe do
      key :type, :boolean
    end
    property :provider do
      key :type, :string
    end
    property :uid do
      key :type, :string
    end
    property :sync_subsections do
      key :type, :boolean
    end
    property :quiz_alert do
      key :type, :boolean
    end
    property :device_token do
      key :type, :string
      key :description, 'iOS device token'
    end
    property :device_type do
      key :type, :string
      key :description, 'Options: iOS, android, windows'
    end

  end

  swagger_schema :UserInput do
    allOf do
      schema do
        key :'$ref', :User
      end
      schema do
        key :required, [:id]
        property :id do
          key :type, :integer
          key :format, :int64
        end
      end
    end
  end

  # ----------------------------------------------------------------------------------------------------------
  # Swagger-Blocks DSL [END]
  # ----------------------------------------------------------------------------------------------------------

  # extend FriendlyId
  # friendly_id :login

  before_save :generate_login

  # Include default devise modules. Others available are:
  # :token_authenticatable, :lockable, trackable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :omniauthable,
         :recoverable, :rememberable, :confirmable, :validatable,
         :encryptable, :encryptor => :restful_authentication_sha1

  validates :name,  :length     => { :maximum => 60 },
                    :allow_nil  => true

  # "validatable" module of devise already handles email validation

  # Relationships
  has_and_belongs_to_many :roles
  has_and_belongs_to_many :quests
  has_and_belongs_to_many :badges

  has_many                :passages,          :dependent   => :destroy
  has_many                :memverses,         :dependent   => :destroy
  has_many                :verses,            :through     => :memverses
  has_many                :quiz_questions,    :foreign_key => :submitted_by

  has_many                :progress_reports,  :dependent => :destroy
  has_many                :tweets
  has_many                :sermons
  belongs_to              :country,         :counter_cache => true
  belongs_to              :church,          :counter_cache => true
  belongs_to              :group,           :counter_cache => true
  belongs_to              :american_state,  :counter_cache => true

  # Record who tagged which verse - not working at the moment
  acts_as_tagger

  # Associations for bloggity
  has_many :blog_posts, :foreign_key => "posted_by_id", :class_name => 'Bloggity::BlogPost'
  has_many :blog_comments, :dependent => :destroy, :class_name => 'Bloggity::BlogComment'
  include BloggityUser

  # Named Scopes
  scope :active,            -> { where('last_activity_date >= ?', 1.month.ago) }
  scope :active_today,      -> { where('last_activity_date = ?',  Date.today) }
  scope :active_this_week,  -> { where('last_activity_date >= ?', 1.week.ago) }
  scope :american,          -> { where('countries.printable_name' => 'United States').includes(:country) }
  scope :pending,           -> { where(:confirmed_at => nil) }

  # Setup accessible (or protected) attributes for your model
  # Prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here
  attr_accessible :login, :email, :name, :password, :password_confirmation, :current_password,
                  :identity_url, :remember_me, :newsletters, :reminder_freq, :last_reminder,
                  :church, :group, :country, :american_state, :show_echo, :max_interval,
                  :mnemonic_use, :all_refs, :referred_by, :auto_work_load, :show_email,
                  :provider, :uid, :translation, :time_allocation, :quiz_alert,
                  :device_token, :device_type

  # Single Sign On support
  def self.find_for_windowslive_oauth2( access_token, signed_in_resource=nil )

    data = access_token.extra.raw_info

    user = User.where( :email => data.emails.account ).first

    # Create new user if one doesn't exist
    #<OmniAuth::AuthHash
    #   emails=#<OmniAuth::AuthHash account="kayle.hinkle@live.com" business=nil personal=nil preferred="kayle.hinkle@live.com">
    #   first_name="Kayle"
    #   gender=nil
    #   id="cfd5745452f3201b"
    #   last_name=nil
    #   locale="en_US"
    #   name="Kayle"
    # >

    unless user
      user = User.create(name: data.name, login: data.name, email: data.emails.account, password: Devise.friendly_token[0,20],
                         provider: access_token.provider, uid: access_token.uid )

      user.confirm! # we can confirm the user since we can rely on a valid email address
    end

    user

  end

  # Convert to JSON format
  def as_json(options={})
    {
      :id            => self.id,
      :name          => self.name_or_login,
      :avatar_url    => self.blog_avatar_url
    }
  end

  # Stringify: Display name
  #
  # @return [String]
  def to_s
    name_or_login
  end

  # Check if a user has a role
  #
  # @param role [String]
  #
  # @return [Boolean]
  def has_role?(role)
    list ||= self.roles.map(&:name)
    list.include?(role.to_s) || list.include?('admin')
  end

  # Link for user to get referral credit
  #
  # @return [String] URL
  def referral_link
    "#{DOMAIN_NAME}"+"/?referrer="+"#{self.login}"
  end

  # Gender-specific pronoun
  #
  # @return [String] "her", "his", "their"
  def his_or_her
    case self.gender
      when "Female" then "her"
      when "Male"   then "his"
      else "their"
    end
  end

  # Check whether current user is memorizing a given chapter in any translation
  # 
  # @param book [String] e.g., "John"
  # @param chapter [Fixnum] e.g., 3
  #
  # @return [Array<Memverse>, nil] Array of Memverses from chapter if present.
  #   Otherwise, nil.
  def has_chapter?(book, chapter)

    book = "Psalms" if book == "Psalm"
    if mv = self.has_verse?(book, chapter, 1)
      return mv.chapter
    else
      return nil
    end
  end

  # Check whether current user is memorizing a given verse in any translation
  #
  # @param book [String]
  # @param chapter [Fixnum]
  # @param versenum [Fixnum]
  #
  # @return Boolean
  def has_verse?(book, chapter, versenum)
    book = "Psalms" if book == "Psalm"
    self.memverses.includes(:verse).where('verses.book' => book, 'verses.chapter' => chapter, 'verses.versenum' => versenum).first
  end

  # Check whether current user is memorizing a given verse
  # @see #has_verse?
  #
  # @param vs_id [Fixnum] 
  # @return [Memverse, nil]
  def has_verse_id?(vs_id)
    self.memverses.where(verse_id: vs_id).first
  end

  # Minutes required daily
  #
  # @return [Fixnum]
  # 
  # @todo This method occasionally returned infinity due to test_interval being zero. This is not the best place
  #       to fix the problem but good enough hack for now.
  def work_load
    time_per_verse = 1.0 # minutes
    verses_per_day = 2.0 # initialize with login, setup time etc
    # self.memverses.active.where(:test_interval => 0).update_all(:test_interval => 1)
    self.memverses.active.find_each { |mv|
      verses_per_day += (1 / mv.test_interval.to_f)
    }
    return (verses_per_day * time_per_verse).round
  end

  # User progression - only used for cohort analysis
  #
  # @todo We should use {#progression} method instead and incorporate into cohort analysis
  def cohort_progression

    has_reviewed_one = memverses.sum(:attempts) > 0         # TRUE if user has reviewed one verse

    if memverses.memorized.count >= 1
      return { :level => '9 - Verse memorized', :active => is_active? }
    elsif completed_sessions >= 3 and has_reviewed_one
      return { :level => '8 - Onwards', :active => is_active? }
    elsif completed_sessions == 2 and has_reviewed_one
      return { :level => '7 - Returned Once', :active => is_active? }
    elsif completed_sessions == 1 and has_reviewed_one
      return { :level => '6 - Completed 1 Session', :active => is_active? }
    elsif has_reviewed_one
      return { :level => '5 - Started a Session', :active => is_active? }
    elsif memverses.count >= 5
      return { :level => '4 - Added 5+ Verses', :active => is_active? }
    elsif memverses.count > 0
      return { :level => '3 - Added 1-4 Verses', :active => is_active? }
    elsif confirmed_at
      return { :level => '2 - Activated', :active =>  is_active? }
    elsif !confirmed_at
      return { :level => '1 - Registered', :active => is_active? }
    else
      return { :level => 'ERROR', :active => false }
    end
  end

  # User progression
  #
  # @return [Fixnum] Scale of 0 to 9 representing user progression.
  def progression

    has_reviewed_one = memverses.sum(:attempts) > 0         # TRUE if user has reviewed one verse

    if memverses.memorized.count >= 1                       # has memorized one or more verses
      return 9
    elsif completed_sessions >= 3 and has_reviewed_one      # regular user who hasn't yet memorized a verse
      return 8
    elsif completed_sessions == 2 and has_reviewed_one      # returning user
      return 7
    elsif completed_sessions == 1 and has_reviewed_one      # completed one session
      return 6
    elsif has_reviewed_one                                  # has reviewed at least one verse at some point
      return 5
    elsif memverses.count >= 5                              # has added 5 or more verses
      return 4
    elsif memverses.count > 0                               # has added 1-5 memory verses
      return 3
    elsif confirmed_at
      return 2
    elsif !confirmed_at
      return 1
    else
      return 0
    end
  end

  # User requires more daily time than they allocated
  #
  # @return [Boolean]
  def overworked?
  	return work_load >= time_allocation
  end

  # User has fallen behind
  #
  # @return [Boolean]
  def swamped?
    return due_verses >= 3 * work_load
  end

  # Convert pending verses to active status
  #
  # @return [Array<Memverse>, false] false if not #auto_work_load, or
  #   #auto_work_load but no time shortfall. Array<Memverse> of pending
  #   Memverses if pending Memverses adjusted.
  def adjust_work_load

  	if self.auto_work_load
      time_shortfall = time_allocation - work_load

      if time_shortfall >= 1

        pending = self.memverses.inactive.order("created_at ASC").limit(time_shortfall)

        # We need to handle memory verses that have been set to 'Pending' but were already memorized
        pending.where("next_test <= ?", Date.today).update_all(next_test: Date.tomorrow)
        pending.where("test_interval > 30").update_all(status: "Memorized")
        pending.where("test_interval <= 30").update_all(status: "Learning")

        return pending
      end

      return false

    end

    return false

  end

  # User hasn't added verses or picked translation
  #
  # These users are sent to the quick start page.
  #
  # @return [Boolean]
  def needs_quick_start?
    !self.translation && self.memverses.count == 0
  end

  # User has verses to memorize
  #
  # @return [Boolean]
  def has_started?
    return self.memverses.count > 0
  end

  # User has active verses
  #
  # @return [Boolean]
  def has_active?
    return self.memverses.active.count > 0
  end

  # Completed sessions over various time periods
  # 
  # @param time_period [Symbol] :week, :month, :year, :total
  #
  # @return [Fixnum] Sessions completed in last time_period (e.g., last week).
  def completed_sessions(time_period = :total)
    sessions = self.progress_reports

    return case time_period
      when :week  then sessions.where('entry_date > ?', 1.week.ago).count
      when :month then sessions.where('entry_date > ?', 1.month.ago).count
      when :year  then sessions.where('entry_date > ?', 1.year.ago).count
      when :total then sessions.count
      else sessions.count
    end
  end

  # Verse Category Stats
  #
  # @param cat [Symbol] :ot, :nt, :history, :wisdom, :prophecy, :gospel, :epistle
  #
  # @return [Hash] "Memorized" and "Learning" count
  def category_verses(cat)
    valid = [:ot, :nt, :history, :wisdom, :prophecy, :gospel, :epistle]
    raise ArgumentError, 'Invalid category symbol' unless valid.include?(cat)

    # category must be [Verse] method
    cat = :old_testament if cat == :ot
    cat = :new_testament if cat == :nt

    { "Memorized" => self.memverses.memorized.send(cat).count,
      "Learning"  => self.memverses.learning.send(cat).count }
  end

  # Verse Category Percentage
  #
  # @param cat [Symbol] :ot, :nt, :history, :wisdom, :prophecy, :gospel, :epistle
  #
  # @return [Fixnum] Percentage of verses in category
  def category_perc(cat)
    return 0 if !self.has_active?

    (category_verses(cat).values.sum.to_f / memverses.active.count.to_f * 100).round
  end

  # Quests still needed for current level
  #
  # @return [Array<Quest>] Quests still needed for user's current level.
  def current_uncompleted_quests
    Quest.where(level: self.level+1) - self.current_completed_quests
  end

  # Quests completed for current level.
  # 
  # Note that quests 'belong' to a user once completed.
  #
  # @return [Array<Quest>] All quests completed for User's current level.
  def current_completed_quests
    self.quests.where(level: self.level+1)
  end

  # Check whether quests are complete and level up if necessary
  # 
  # @return [Boolean] Was level completed?
  def check_for_level_up
    if self.level_complete?
      self.level_up
      return true
    else
      return false
    end
  end

  # All quests for current level complete?
  #
  # @return [Boolean]
  def level_complete?
    self.current_uncompleted_quests.empty?
  end

  # Level up user
  #
  # @return [void]
  def level_up
    self.level += 1
    self.save

    # @todo Need to check whether tasks have been completed for the new level already
  end

  # Check for completed quests
  #
  # @return [Array<Quest>] array of newly completed quests
  def check_for_completed_quests

    newly_completed_quests = Array.new

    quests_to_check = self.current_uncompleted_quests

    quests_to_check.each { |q|
      if q.complete?(self)
        q.check_quest_off(self)
        newly_completed_quests << q
      end
    }

    return newly_completed_quests.empty? ? nil : newly_completed_quests

  end


  # Badges that user is working towards
  #
  # @return [Array<Badge>] Array of badges user is working towards
  def badges_to_strive_for
    # need to handle gold, silver, bronze issue
    # first generate a list of badges the user would be interested in earning i.e. all badges of higher level
    # or unearned solo badges.

    user_badges   = self.badges
    lesser_badges = Array.new

    user_badges.each do |user_badge|
      Rails.logger.debug("User already has #{user_badge.color} #{user_badge.name}")
      Badge.where(:name => user_badge.name).each do |badge_in_series|
        if badge_in_series <= user_badge
          Rails.logger.debug("Removing #{user_badge.color} #{user_badge.name} from list of badges to strive for.")
          lesser_badges << badge_in_series
        end
      end
    end

    Rails.logger.debug("Final list of badges to strive for: #{Badge.all - lesser_badges}")

    return Badge.all - lesser_badges
  end

  # Create progress report or update existing.
  #
  # @return [void]
  def save_progress_report # usually called via AJAX as log_progress

    has_reviewed_one = memverses.sum(:attempts) > 0  # TRUE if user has reviewed one verse

    if has_reviewed_one # only save a progress report if the user has reviewed a verse
      
      # check whether there is already a ProgressReport for today
      pr = self.progress_reports.where(entry_date: Date.today).first

      # create a progress report if one doesn't exist for today
      if pr.nil?
        pr = ProgressReport.new(user: self, entry_date: Date.today)
      end

      # if there is already a ProgressReport for today, update it
      pr.memorized        = self.memorized
      pr.learning         = self.learning
      pr.time_allocation  = self.work_load

      pr.save
    end

  end

  # List of referrals
  #
  # @param active Boolean If true, only active referrals will be returned.
  #   Otherwise, all referrals will be returned.
  # @return [Array<User>] list of people user has referrred
  def referrals( active = false )
    if active
      User.active.where(referred_by: self.id)
    else
      User.where(referred_by: self.id)
    end
  end

  # Number of people user referred
  #
  # @param active Boolean If true, only active referrals will be counted.
  #   Otherwise, all referrals will be returned.
  # @return [Fixnum]
  def num_referrals( active = false )
    self.referrals(active).count
  end

  # Referral score
  #
  # Used for calculating referral board and for quests. Active referrals are
  # worth 1 point; inactive, 1/2 point; and referrals of referrals, 1/4 point.
  #
  # @return [Float]
  def referral_score

    score  = self.num_referrals( active=false ) / 2.to_f  # + 1/2 for every referral
    score += self.num_referrals( active=true  ) / 2.to_f  # + 1/2 for every active referral

    self.referrals( active=false ).find_each { |r|        # + 1/4 for referrals of referrals
      score += r.num_referrals( active=false ) / 4.to_f
    }

    return score

  end

  # Has user finished a day of memorization?
  #
  # @return [Boolean]
  def finished_a_mem_session?
    self.progress_reports.count > 0
  end

  # Number of tags a user has applied
  #
  # @return [Fixnum]
  def num_taggings
    ActsAsTaggableOn::Tagging.where(tagger_type: "user", tagger: self).count
  end

  # List of complete chapters that user is memorizing
  #
  # @return [Array<Array<String,String>>]
  #   Example: [["Memorized", "John 1"], ["Learning", "John 2"]]
  #
  # @todo Is more optimization required? Page load time for user with lots of complete books was 40 secs.
  def complete_chapters
    cc = Array.new

    # Get all memory verses for user that are the first verse in a chapter
    start_mv = self.memverses.canonical_sort.where('verses.versenum' => 1)
    start_mv.each { |smv|
      if smv.part_of_entire_chapter?
        if smv.chapter_memorized?
          cc << ["Memorized", smv.verse.chapter_name]
        elsif !smv.chapter_pending?
          cc << ["Learning",  smv.verse.chapter_name]
        end
      end
    }

    return cc

  end

  # User's name (or login, if name empty)
  #
  # @return [String] name or login
  def name_or_login
    self.name.empty? ? self.login : self.name
  end

  # Update user profile
  # 
  # @param new_params Params from 'update_profile' form
  # @return [Boolean] successful or not
  def update_profile(new_params)
    return false if new_params.nil?

    self.name             = new_params["name"]
    self.email            = new_params["email"]
    self.gender           = new_params["gender"]
    self.translation      = new_params["translation"]
    self.reminder_freq    = new_params["reminder_freq"]
    self.country          = Country.where(printable_name: new_params["country"]).first
    self.american_state   = AmericanState.where(name: new_params["american_state"]).first
    # If church, group doesn't exist in database we add it
    self.church           = Church.where(name: new_params["church"]).first || Church.create(name: new_params["church"])
    self.group            = Group.where(name: new_params["group"]).first || Group.create(name: new_params["group"], leader_id: self.id)
    self.newsletters      = new_params["newsletters"]
    self.language         = new_params["language"]
    self.time_allocation  = new_params["time_allocation"]
    self.show_echo        = new_params["show_echo"]
    self.mnemonic_use     = new_params["mnemonic_use"]
    self.auto_work_load   = new_params["auto_work_load"]
    self.sync_subsections = new_params["sync_subsections"]
    self.all_refs         = new_params["all_refs"]
    self.max_interval     = new_params["max_interval"]
    self.show_email       = new_params["show_email"]

    if self.valid? # We shouldn't call self.save unless this is valid
      self.save
    end
  end

  # Reset the spacing of memory verses
  # 
  # @todo Refactor
  def reset_memorization_schedule

    load_target    = self.work_load # number of minutes user is required to do each day to keep up with review

    # get list of id's of memverses that overdue
    load_for_today = self.memverses.active.where("next_test <= ?", Date.today).order("next_test ASC").select("id").map(&:id)
    offset         = 0

    for i in 1..load_for_today.length # iterate through array of memverse ID's

      if (i % load_target == 0) # if divisible by load_target
        Memverse.where("id in (?)", load_for_today[(offset * load_target)..(i-1)]).update_all(:next_test => Date.today + offset)
        offset = offset + 1
      elsif ((i-1) % load_target == 0) && ((i-1) + load_target > load_for_today.length) # if just passed last i divisible by load_target
        Memverse.where("id in (?)", load_for_today[(offset * load_target)..(load_for_today.length-1)]).update_all(:next_test => Date.today + offset)
        offset = offset + 1
      else
        # do nothing
      end

    end

    # Update all passages
    # @todo this is currently very inefficient. Using update_all, however, does not trigger the callbacks for the passage model
    self.passages.each { |psg|
      psg.update_next_test_date
    }

    return due_verses

    # extend future verses if necessary
    # @todo call a generic load smoothing function to space out verses evenly. Might not be worth doing given that
    # each day's memorization session changes the future load
  end

  # Reset passages
  #
  # @return [void]
  def recreate_passages

    # Delete all existing passages
    self.passages.delete_all

    # Find all starting (or solo verses) and create a passage
    self.memverses.where(first_verse: nil).find_each { |mv|
      pp = Passage.create!(

        :user           => self,

        :reference      => mv.verse.ref,
        :translation    => mv.verse.translation,

        :book           => mv.verse.book,
        :chapter        => mv.verse.chapter,
        :first_verse    => mv.verse.versenum,
        :last_verse     => mv.verse.versenum,

        :length         => 1,

        :efactor        => mv.efactor,
        :test_interval  => mv.test_interval,
        :rep_n          => 1,
        :next_test      => mv.next_test,
        :last_tested    => mv.last_tested )

      if pp
        mv.passage_id = pp.id
        mv.save
      else
        Rails.logger.error("=====> Error creating passage for memory verse (#{mv.ref}) for user (#{self.login})")
      end
    }

    # Find all other verses and add to existing passage
    self.memverses.where(Memverse.arel_table[:first_verse].not_eq(nil)).find_each { |mv|
      mv.add_to_passage
    }

  end

  # Number of overdue verses (does not include verses that are due today)
  #
  # @return [Fixnum]
  def overdue_verses
    self.memverses.active.where("next_test < ?", Date.today).count
  end

  # Number of due verses
  #
  # @return [Fixnum]
  def due_verses
    self.memverses.active.where("next_test <= ?", Date.today).count
  end

  # Number of due verse references
  #
  # @return [Fixnum]
  def due_refs
    return self.memverses.active.ref_due.count if self.all_refs

    return self.memverses.active.passage_start.ref_due.count
  end

  # First verse due today
  #
  # @return [Memverse, nil]
  def first_verse_today
    mv = self.memverses.active.order("next_test ASC").first

    return mv.first_verse_due_in_sequence if mv && mv.due?

    return nil
  end

  # Upcoming verses that need to be tested today
  #
  # @param strict
  #   If true, return only the individual verses that are strictly due today.
  #   If false, return verse sequences as likely to be tested (get rid of this?).
  # @return [Array<Memverse>, nil]
  def upcoming_verses(limit = 20, mode = "test", mv_id = nil, strict = true)

  	upcoming = Array.new

  	if strict and mode == 'test'
  		upcoming = self.memverses.active.where("next_test <= ?", Date.today).order("next_test ASC")
  	else
	    mvs = self.memverses.active.where("next_test <= ?", Date.today).order("next_test ASC").limit(limit)
	    current_mv = Memverse.find(mv_id) unless mv_id.nil?

	    mvs.collect! { |mv|

	        # First handle the case where this is not a starting verse
	        if mv.first_verse? # i.e. there is an earlier verse in the sequence
	          # Either return first verse that is due in the sequence
	          if mv.sequence_length > 5 and mode == "test"
	            mv.first_verse_due_in_sequence   # This method returns the first verse due as an object
	          # Or return the first verse no matter what if it is a short sequence
	          else
	            Memverse.find( mv.first_verse )  # Go find the first verse
	          end
	        # Otherwise, this is a first verse so just return it
	        else
	          mv
	        end
	    }.uniq!  # this handles the case where multiple verses are pointing to a first verse
	    # @todo how should we sort the upcoming verses
	    # @todo we should convert passages into Gen 1:1-10

	    # At this point, mvs array contains all the starting verses due today. Now we add the downstream verses
	    mvs.each { |mv|

	        upcoming << mv unless mv.prior_in_passage_to?(current_mv) || mv.inactive?

	        # Add any subsequent verses in the chain
	        next_verse = mv.next_verse
	        if next_verse
	          cmv = Memverse.find( next_verse )
	        end
	        while (next_verse) && cmv.more_to_memorize_in_sequence?
	          cmv         = Memverse.find(next_verse)
	          upcoming   << cmv unless cmv.prior_in_passage_to?(current_mv) || cmv.inactive?
	          next_verse  = cmv.next_verse
	        end
	    }
    end

    return upcoming
  end


  # Change reminder frequency for inactive users
  #
  # Users who have missed multiple reminders under the current frequency are
  # bumped down to a lower frequency.
  def update_reminder_freq

    last_reminded     = self.last_reminder || (Date.today - 100) # handles case where user has never been reminded
    last_activity     = self.last_activity_date || self.created_at.to_date # use created date if no activity ever
    reminder_freq     = self.reminder_freq
    days_since_active = (Date.today - last_activity).to_i

    # If any activity in last while then no need to update
    return if reminder_freq == "Never" || days_since_active < 45

    policy = [
      {freq: "Quarterly", days: 365, schedule: "an annual", new_freq: "Annually"},
      {freq: "weekly", days: 10, schedule: "monthly", new_freq: "Never"}, # Users who never set reminder frequency
      {freq: "Weekly", days: 40, schedule: "monthly", new_freq: "Monthly"},
      {freq: "Monthly", days: 65, schedule: "quarterly", new_freq: "Quarterly"},
      {freq: "Daily", days: 25, schedule: "weekly", new_freq: "Weekly"}
    ]

    for case_ in policy
      if reminder_freq == case_[:freq] && days_since_active > case_[:days]
        logger.info("*** Changing reminder frequency for #{self.login} to #{case_[:schedule]} schedule. Last activity was #{days_since_active} days ago")
        self.update_column(:reminder_freq, case_[:new_freq])
      end
    end
  end

  # Check whether user needs reminder
  #
  # @return [Boolean]
  def needs_reminder?

    last_reminded = self.last_reminder || (Date.today - 100) # handles case where user has never been reminded

    # Count a login as a reminder if login is more recent than the reminder. This avoids the case where a user gets
    # a reminder the day after they've logged in when they only want weekly reminders
    if last_reminded < (self.last_activity_date || last_reminded)
      last_reminded = self.last_activity_date
    end

    mv           = self.memverses.order("next_test ASC").first
    days_overdue = mv ? (Date.today - mv.next_test).to_i : 30                   # If user hasn't added verses then regard them as 1 month overdue

    if self.reminder_freq == "Never"
      return false
    elsif last_reminded + reminder_in_days(self.reminder_freq) < Date.today     # Check for emailing users too frequently ...
      return ( days_overdue > reminder_in_days(self.reminder_freq) )            # ... then check whether user needs to be reminded
    else
      return false
    end
  end

  # Delete a user's account
  #
  # @return [void]
  def delete_account

    # Remove user's memory verses
    user_mv = self.memverses
    Rails.logger.info("===== Removing user #{self.login} and his/her #{user_mv.length} memory verses =========")
    user_mv.each { |mv|
      logger.info("|  -- Deleting memory verse #{mv.id}")
      mv.destroy
    }

    # @todo Potentially delete their church if they're the only member

    self.destroy

  end

  # [DISABLED] Delete accounts of users that never added any verses
  #
  # Instead of deleting users, this method writes to the log that the user
  # should be deleted.
  def self.delete_users_who_never_started

    # @todo What about pending verses? Is this method used?

    where("created_at < ?", 3.months.ago).where(learning: 0, memorized: 0).each { |u|
      # u.destroy
      Rails.logger.info("We should remove user #{u.login} - they haven't got started in over three months")
    }
  end


  # Unsubscribe from all email
  #
  # @return [Boolean] true if successfully saved
  def unsubscribe
    self.newsletters    = false
    self.reminder_freq  = "Never"
    self.save
  end

  # Tweet about user
  #
  # @param news [String] Announcement about the user
  # @param importance [Fixnum] The importance of the announcement (Tweet).
  def broadcast(news, importance)
    Tweet.create(news: "#{self} #{news}", user: self, importance: importance)
  end

  # User about to reach a milestone
  #
  # @return [Boolean]
  def reaching_milestone
    [9, 24, 49, 99, 199, 299, 499, 999, 1499, 1999, 2999, 3999, 4999, 9999].
    include?(self.memorized)
  end

  # Tweet about user reaching milestone
  #
  # @return [void] Note, however, that a Tweet is created.
  def tweet_milestone
    milestone = self.memorized+1

    importance = case milestone
      when    0..    9 then 4
      when   10..  499 then 3
      when  500..  999 then 2
      when 1000..10000 then 1
      else                  5
    end

    news = "memorized #{self.his_or_her} #{milestone}th verse"
    self.broadcast(news, importance)
  end

  # Most difficult verse
  #
  # @return [Memverse, nil]
  def most_difficult_vs
    self.memverses.order("efactor ASC").first
  end

  # Random difficult verse
  #
  # @return [Memverse, nil]
  def random_verse
    self.memverses.order("efactor ASC").limit(10).sample
  end


  # Time until next verse is due for review
  #
  # @return [String, nil] "today", "tomorrow", "in x days", "in more than a week", nil
  def next_verse_due
    mv = self.memverses.active.order("next_test ASC").first

    return nil if mv.nil? # User has no active memory verses

    days_to_next_review = (mv.next_test - Date.today).to_i

    return case days_to_next_review
      when 0      then "today"
      when 1      then "tomorrow"
      when 2..7   then "in #{days_to_next_review} days"
      when 7..366 then "in more than a week"
      else             "in more than a week"
    end
  end


  # Date of last activity
  # 
  # Only used during migration; now handled with a counter cache.
  #
  # @return [Date] Activity of either testing a verse or adding a new verse (not yet added).
  def init_activity_date
    mv = self.memverses.order("last_tested DESC").first
    if mv
      return mv.last_tested
    else
      return created_at.to_date # if user hasn't added verses then just use the day they signed up
    end
  end

  # User status
  # 
  # @return [String] "Active" or "Inactive"
  def status
    self.is_active? ? "Active" : "Inactive"
  end

  # User has been active in last month
  #
  # @return [Boolean]
  def is_active?
    self.last_activity_date && self.last_activity_date > 1.month.ago.to_date
  end

  # User has not been active for two months or more
  #
  # @return [Boolean] True if user was active but now is not. False if never active or still active.
  def is_inactive?
    # Remember, nil evaluates to false => a user who never activated will never be 'inactive'
    self.last_activity_date && self.last_activity_date < 3.months.ago.to_date
  end

  # Check whether user needs encouragement
  #
  # @return [Boolean]
  # def needs_kick_in_pants?

  #   if self.has_started? or !self.confirmed_at  # user already has verses or never activated their account
  #     return false
  #   else
  #     if self.last_reminder.nil? and  days_since_contact_or_login > 1 # user has never been reminded
  #       Rails.logger.debug("*** #{self.login} has never been encouraged and two days have elapsed since registration")
  #       return true
  #     elsif days_since_contact_or_login > 31 # space reminders out by one month
  #       Rails.logger.debug("*** #{self.login} was last encouraged a month ago but still hasn't added a verse")
  #       return true
  #     else
  #       return false
  #     end
  #   end
  # end

  # Has it been a week since the last reminder?
  # 
  # @return [Boolean]
  def week_since_last_reminder?
    if self.last_reminder.nil?
      return true
    end
    
    return (Date.today - self.last_reminder) > 6
  end

  # Days since we last contacted user or they logged in
  #
  # @return [Fixnum]
  def days_since_contact_or_login

    last_reminded = self.last_reminder || self.created_at.to_date
    last_login    = self.updated_at.to_date

    return [Date.today-last_reminded, Date.today-last_login].max.to_i
  end

  # Pending verses for user
  #
  # @return [Array<Memverse>]
  def pending
    self.memverses.inactive
  end

  # Top memorizers
  # 
  # @return [Array<User>] Top 250 users, sorted by number of verses memorized
  def self.top_users
    User.active.order("memorized DESC").limit(250).
    select("id, login, name, created_at, church_id, country_id,
      memorized, learning, accuracy, ref_grade, level")
  end

  # Top referrers
  #
  # @param numusers The number of users to return
  #
  # @return [Array<User>] Users with the most referrals
  def self.top_referrers(numusers=50)
    leaderboard = Hash.new(0)

    active.find_each { |u| leaderboard[ u ] = u.referral_score }

    return leaderboard.sort{|a,b| a[1]<=>b[1]}.reverse[0...numusers]
  end

  # Fix verse linkage: set repair = true to fix problems
  # 
  # @param repair [Boolean] Set to true to fix problems
  def fix_verse_linkage(repair = false)

    report = Array.new

    self.memverses.find_each { |mv|

      record            = Hash.new
      record['mvID']    = mv.id
      record['Ref']     = mv.verse.ref
      # Add multi-verse linkage
      if mv.prev_verse != mv.get_prev_verse
        logger.warn("*** WARNING: Had to add linkage to previous verse for memory verse #{mv.id}")
        record['Prev'] = repair ? 'Fixed' : 'Error'
        mv.prev_verse = mv.get_prev_verse unless !repair
      else
        logger.debug("*** #{mv.id} : Prev verse link OK")
        record['Prev'] = '-'
      end

      if mv.next_verse   != mv.get_next_verse
        logger.warn("*** WARNING: Had to add linkage to next verse for memory verse #{mv.id}")
        record['Next'] = repair ? 'Fixed' : 'Error'
        mv.next_verse = mv.get_next_verse unless !repair
      else
        logger.debug("*** #{mv.id} : Next verse link OK")
        record['Next'] = '-'
      end

      # @todo Need to fix first verse entry as well
      if mv.first_verse != mv.get_first_verse
        logger.warn("*** WARNING: Had to add linkage to first verse for memory verse #{mv.id}")
        record['First'] = repair ? 'Fixed' : 'Error'
        mv.first_verse = mv.get_first_verse unless !repair
      else
        logger.debug("*** #{mv.id} : First verse link OK")
        record['First'] = '-'
      end

      mv.save
      report << record
    }
    return report
  end

  # ============= Protected below this line ==================================================================

  protected

  def make_activation_code
    self.deleted_at = nil
    self.activation_code = self.class.make_token
  end

  def reminder_in_days(reminder_freq)
    return case reminder_freq.capitalize
      when "Weekly"   then 7
      when "Daily"    then 1
      when "Monthly"  then 30
      when "Quarterly"then 90
      when "Annually" then 365
      when "Never"    then 999 # shouldn't get here
      else                 999 # just to be safe assume lengthy reminder interval on erroneous input
    end
  end

  def normalize_identity_url
    self.identity_url = OpenIdAuthentication.normalize_url(identity_url) unless not_using_openid?
  rescue URI::InvalidURIError
    errors.add_to_base("Invalid OpenID URL")
  end

  def generate_login
    if !self.login?
      login = self.name.parameterize
	  x = 1
	  while User.find_by_login(login) do
	    x += 1
	    login = self.name.parameterize + "--" + x.to_s
	  end
	  self.login = login
	end
  end

end
