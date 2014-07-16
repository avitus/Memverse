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
  # extend FriendlyId
  # friendly_id :login

  before_save :generate_login

  # Include default devise modules. Others available are:
  # :token_authenticatable, :lockable, trackable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :omniauthable,
         :recoverable, :rememberable, :confirmable, :validatable,
         :encryptable, :encryptor => :restful_authentication_sha1

  validates :name,  :length     => { :maximum => 100 },
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
                  :provider, :uid

  # ----------------------------------------------------------------------------------------------------------
  # Single Sign On support
  # ----------------------------------------------------------------------------------------------------------
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

  # ----------------------------------------------------------------------------------------------------------
  # Convert to JSON format
  # ----------------------------------------------------------------------------------------------------------
  def as_json(options={})
    {
      :id            => self.id,
      :name          => self.name_or_login,
      :avatar_url    => self.blog_avatar_url
    }
  end

  # ----------------------------------------------------------------------------------------------------------
  # Display name
  # ----------------------------------------------------------------------------------------------------------
  def to_s
    name_or_login
  end

  # ----------------------------------------------------------------------------------------------------------
  # Check if a user has a role
  # ----------------------------------------------------------------------------------------------------------
  def has_role?(role)
    list ||= self.roles.map(&:name)
    list.include?(role.to_s) || list.include?('admin')
  end

  # ----------------------------------------------------------------------------------------------------------
  # Link to get referral credit
  # ----------------------------------------------------------------------------------------------------------
  def referral_link
    "#{DOMAIN_NAME}"+"/?referrer="+"#{self.login}"
  end

  # ----------------------------------------------------------------------------------------------------------
  # Gender-specific pronouns are cool
  # ----------------------------------------------------------------------------------------------------------
  def his_or_her
    case self.gender
      when "Female" then "her"
      when "Male"   then "his"
      else "their"
    end
  end

  # ----------------------------------------------------------------------------------------------------------
  # Check whether current user is memorizing a given chapter in any translation
  # Input: "John", 3
  # Output: chapter array (if found) or nil (if not)
  # ----------------------------------------------------------------------------------------------------------
  def has_chapter?(book, chapter)

    book = "Psalms" if book == "Psalm"
    if mv = self.has_verse?(book, chapter, 1)
      return mv.chapter
    else
      return nil
    end
  end

  # ----------------------------------------------------------------------------------------------------------
  # Check whether current user is memorizing a given verse in any translation
  # ----------------------------------------------------------------------------------------------------------
  def has_verse?(book, chapter, versenum)
    book = "Psalms" if book == "Psalm"
    self.memverses.includes(:verse).where('verses.book' => book, 'verses.chapter' => chapter, 'verses.versenum' => versenum).first()
  end

  # ----------------------------------------------------------------------------------------------------------
  # Check whether current user is memorizing a given verse (see also: 'has_verse' method above)
  # Input: verse_id
  # Returns: TRUE if user has verse in userlist else FALSE
  # ----------------------------------------------------------------------------------------------------------
  def has_verse_id?(vs_id)
    ref = self.memverses.where(verse_id: vs_id).first
    return ref
  end

  # ----------------------------------------------------------------------------------------------------------
  # Returns number of minutes required each day
  # TODO: This method occasionally returned infinity due to test_interval being zero. This is not the best place
  #       to fix the problem but good enough hack for now.
  # ----------------------------------------------------------------------------------------------------------
  def work_load
    time_per_verse = 1.0 # minutes
    verses_per_day = 2.0 # initialize with login, setup time etc
    # self.memverses.active.where(:test_interval => 0).update_all(:test_interval => 1)
    self.memverses.active.find_each { |mv|
      verses_per_day += (1 / mv.test_interval.to_f)
    }
    return (verses_per_day * time_per_verse).round
  end

  # ----------------------------------------------------------------------------------------------------------
  # User progression - only used for cohort analysis
  # Todo: We should use method below instead and incorporate into cohort analysis
  # ----------------------------------------------------------------------------------------------------------
  def cohort_progression
    if completed_sessions >= 3
      return { :level => '7 - Onwards', :active => is_active? }
    elsif completed_sessions == 2
      return { :level => '6 - Returned Once', :active => is_active? }
    elsif completed_sessions == 1
      return { :level => '5 - Completed 1 Session', :active => is_active? }
    elsif memverses.sum(:attempts) > 0
      return { :level => '4 - Started a Session', :active => is_active? }
    elsif has_started?
      return { :level => '3 - Added Verses', :active => is_active? }
    elsif confirmed_at
      return { :level => '2 - Activated', :active =>  is_active? }
    elsif !confirmed_at
      return { :level => '1 - Registered', :active => is_active? }
    else
      return { :level => 'ERROR', :active => false }
    end
  end

  # ----------------------------------------------------------------------------------------------------------
  # User progression
  # ----------------------------------------------------------------------------------------------------------
  def progression
    if completed_sessions >= 3
      return 7
    elsif completed_sessions == 2
      return 6
    elsif completed_sessions == 1
      return 5
    elsif memverses.sum(:attempts) > 0      # has reviewed at least one verse at some point
      return 4
    elsif has_started?
      return 3
    elsif confirmed_at
      return 2
    elsif !confirmed_at
      return 1
    else
      return 0
    end
  end

  # ----------------------------------------------------------------------------------------------------------
  # TRUE if user requires more time per day than their allocation
  # ----------------------------------------------------------------------------------------------------------
  def overworked?
  	return work_load >= time_allocation
  end

  # ----------------------------------------------------------------------------------------------------------
  # TRUE if user has fallen behind
  # ----------------------------------------------------------------------------------------------------------
  def swamped?
    return due_verses >= 3 * work_load
  end

  # ----------------------------------------------------------------------------------------------------------
  # Convert pending verses to active status
  # ----------------------------------------------------------------------------------------------------------
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

    end

    return false

  end

  # ----------------------------------------------------------------------------------------------------------
  # User hasn't added verses or picked translation => send to quick start page
  # ----------------------------------------------------------------------------------------------------------
  def needs_quick_start?
    !self.translation && self.memverses.count == 0
  end

  # ----------------------------------------------------------------------------------------------------------
  # Check whether current user is memorizing any verses at all
  # ----------------------------------------------------------------------------------------------------------
  def has_started?
    return self.memverses.count > 0
  end

  # ----------------------------------------------------------------------------------------------------------
  # Check whether current user has any active verses
  # ----------------------------------------------------------------------------------------------------------
  def has_active?
    return self.memverses.active.count > 0
  end

  # ----------------------------------------------------------------------------------------------------------
  # Completed sessions over various time periods
  # ----------------------------------------------------------------------------------------------------------
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

  # ----------------------------------------------------------------------------------------------------------
  # Return hash of OT Verses memorized and learning
  # ----------------------------------------------------------------------------------------------------------
  def ot_verses
    { "Memorized" => self.memverses.memorized.old_testament.count,
      "Learning"  => self.memverses.learning.old_testament.count }
  end

  def ot_perc
    self.has_active? ? (self.memverses.active.old_testament.count.to_f / self.memverses.active.count.to_f * 100).round : 0
  end

  # ----------------------------------------------------------------------------------------------------------
  # Return hash of NT Verses memorized and learning
  # ----------------------------------------------------------------------------------------------------------
  def nt_verses
    { "Memorized" => self.memverses.memorized.new_testament.count,
      "Learning"  => self.memverses.learning.new_testament.count }
  end

  def nt_perc
    self.has_active? ? (self.memverses.active.new_testament.count.to_f / self.memverses.active.count.to_f * 100).round : 0
  end

  # ----------------------------------------------------------------------------------------------------------
  # Return hash of History Verses memorized and learning
  # ----------------------------------------------------------------------------------------------------------
  def history
    { "Memorized" => self.memverses.memorized.history.count,
      "Learning" => self.memverses.learning.history.count }
  end

  def h_perc
    self.has_active? ? (self.memverses.active.history.count.to_f / self.memverses.active.count.to_f * 100).round : 0
  end

  # ----------------------------------------------------------------------------------------------------------
  # Return hash of Wisdom Verses memorized and learning
  # ----------------------------------------------------------------------------------------------------------
  def wisdom
    { "Memorized" => self.memverses.memorized.wisdom.count,
      "Learning" => self.memverses.learning.wisdom.count }
  end

  def w_perc
    self.has_active? ? (self.memverses.active.wisdom.count.to_f / self.memverses.active.count.to_f * 100).round : 0
  end

  # ----------------------------------------------------------------------------------------------------------
  # Return hash of Prophecy Verses memorized and learning
  # ----------------------------------------------------------------------------------------------------------
  def prophecy
    { "Memorized" => self.memverses.memorized.prophecy.count,
      "Learning" => self.memverses.learning.prophecy.count }
  end

  def p_perc
    self.has_active? ? (self.memverses.active.prophecy.count.to_f / self.memverses.active.count.to_f * 100).round : 0
  end

  # ----------------------------------------------------------------------------------------------------------
  # Return hash of Gospel Verses memorized and learning
  # ----------------------------------------------------------------------------------------------------------
  def gospel
    { "Memorized" => self.memverses.memorized.gospel.count,
      "Learning" => self.memverses.learning.gospel.count }
  end

  def g_perc
    self.has_active? ? (self.memverses.active.gospel.count.to_f / self.memverses.active.count.to_f * 100).round : 0
  end

  # ----------------------------------------------------------------------------------------------------------
  # Return hash of Epistle Verses memorized and learning
  # ----------------------------------------------------------------------------------------------------------
  def epistle
    { "Memorized" => self.memverses.memorized.epistle.count,
      "Learning" => self.memverses.learning.epistle.count }
  end

  def e_perc
    self.has_active? ? (self.memverses.active.epistle.count.to_f / self.memverses.active.count.to_f * 100).round : 0
  end

  # ----------------------------------------------------------------------------------------------------------
  # Returns all quests still needed for user's current level
  # ----------------------------------------------------------------------------------------------------------
  def current_uncompleted_quests
    Quest.where(level: self.level+1) - self.current_completed_quests
  end

  # ----------------------------------------------------------------------------------------------------------
  # Returns all quests completed for user's current level (Quests 'belong' to a user once completed)
  # ----------------------------------------------------------------------------------------------------------
  def current_completed_quests
    self.quests.where(level: self.level+1)
  end

  # ----------------------------------------------------------------------------------------------------------
  # Check whether quests are complete and level up if necessary
  # ----------------------------------------------------------------------------------------------------------
  def check_for_level_up
    if self.level_complete?
      self.level_up
      return true
    else
      return false
    end
  end

  # ----------------------------------------------------------------------------------------------------------
  # All quests for current level complete?
  # ----------------------------------------------------------------------------------------------------------
  def level_complete?
    self.current_uncompleted_quests.empty?
  end

  # ----------------------------------------------------------------------------------------------------------
  # Level up user
  # ----------------------------------------------------------------------------------------------------------
  def level_up

    self.level += 1
    self.save

    # TODO: Need to check whether tasks have been completed for the new level already

  end

  # ----------------------------------------------------------------------------------------------------------
  # Return array of newly completed quests
  # ----------------------------------------------------------------------------------------------------------
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


  # ----------------------------------------------------------------------------------------------------------
  # Badges that user is working towards
  # ----------------------------------------------------------------------------------------------------------
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

  # ----------------------------------------------------------------------------------------------------------
  # Create progress report or update existing
  # ----------------------------------------------------------------------------------------------------------
  def save_progress_report

    # Check whether there is already an entry for today
    pr = self.progress_reports.where(entry_date: Date.today).first

    if pr.nil?
      pr = ProgressReport.new(user: self, entry_date: Date.today)
    end

    pr.memorized        = self.memorized
    pr.learning         = self.learning
    pr.time_allocation  = self.work_load

    pr.save

  end

  # ----------------------------------------------------------------------------------------------------------
  # Return list of people a user has referred
  # ----------------------------------------------------------------------------------------------------------
  def referrals( active = false )
    if active
      User.active.where(referred_by: self.id)
    else
      User.where(referred_by: self.id)
    end
  end

  # ----------------------------------------------------------------------------------------------------------
  # Return number of people a user has referred
  # ----------------------------------------------------------------------------------------------------------
  def num_referrals( active = false )
    self.referrals(active).count
  end

  # ----------------------------------------------------------------------------------------------------------
  # Referral score - used for calculating referral board and for quests
  # ----------------------------------------------------------------------------------------------------------
  def referral_score

    score  = self.num_referrals( active=false ) / 2.to_f  # + 1/2 for every referral
    score += self.num_referrals( active=true  ) / 2.to_f  # + 1/2 for every active referral

    self.referrals( active=false ).find_each { |r|        # + 1/4 for referrals of referrals
      score += r.num_referrals( active=false ) / 4.to_f
    }

    return score

  end

  # ----------------------------------------------------------------------------------------------------------
  # Has user ever finished a day of memorization
  # ----------------------------------------------------------------------------------------------------------
  def finished_a_mem_session?
    return self.progress_reports.count > 0
  end

  # ----------------------------------------------------------------------------------------------------------
  # Number of tags a user has applied
  # ----------------------------------------------------------------------------------------------------------
  def num_taggings
    ActsAsTaggableOn::Tagging.where(tagger_type: "user", tagger: self).count
  end

  # ----------------------------------------------------------------------------------------------------------
  # Returns list of complete chapters that user is memorizing
  # TODO: Is more optimization required? Page load time for user with lots of complete books was 40 secs.
  # ----------------------------------------------------------------------------------------------------------
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

  # ----------------------------------------------------------------------------------------------------------
  # Returns user's name or login
  # ----------------------------------------------------------------------------------------------------------
  def name_or_login
    self.name.empty? ? self.login : self.name
  end

  # ----------------------------------------------------------------------------------------------------------
  # Update user profile
  # Input: Params from 'update_profile' form
  # ----------------------------------------------------------------------------------------------------------
  def update_profile(new_params)

    self.name             = new_params["name"]
    self.email            = new_params["email"]
    self.gender           = new_params["gender"]
    self.translation      = new_params["translation"]
    self.reminder_freq    = new_params["reminder_freq"]
    self.country          = Country.where(:printable_name => new_params["country"]).first
    self.american_state   = AmericanState.where(:name => new_params["american_state"]).first
    # If church, group doesn't exist in database we add it
    self.church           = Church.where(:name => new_params["church"]).first || Church.create(:name => new_params["church"])
    self.group            = Group.where(:name => new_params["group"]).first || Group.create(:name => new_params["group"], :leader_id => self.id)
    self.newsletters      = new_params["newsletters"]
    self.language         = new_params["language"]
    self.time_allocation  = new_params["time_allocation"]
    self.show_echo        = new_params["show_echo"]
    self.mnemonic_use     = new_params["mnemonic_use"]
    self.all_refs         = new_params["all_refs"]
    self.auto_work_load   = new_params["auto_work_load"]
    self.max_interval     = new_params["max_interval"]
    self.show_email       = new_params["show_email"]

    if self.valid? # We shouldn't call self.save unless this is valid
      self.save
    end
  end

  # ----------------------------------------------------------------------------------------------------------
  # Reset the spacing of memory verses
  # TODO: Refactor
  # ----------------------------------------------------------------------------------------------------------
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
    # TODO: this is currently very inefficient. Using update_all, however, does not trigger the callbacks for the passage model
    self.passages.each { |psg|
      psg.update_next_test_date
    }

    return due_verses

    # extend future verses if necessary
    # TODO: call a generic load smoothing function to space out verses evenly. Might not be worth doing given that
    # each day's memorization session changes the future load
  end

  # ----------------------------------------------------------------------------------------------------------
  # Reset passages
  # ----------------------------------------------------------------------------------------------------------
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

  # ----------------------------------------------------------------------------------------------------------
  # Returns number of overdue verses (does not include verses that are due today)
  # ----------------------------------------------------------------------------------------------------------
  def overdue_verses
    self.memverses.active.where("next_test < ?", Date.today).count
  end

  # ----------------------------------------------------------------------------------------------------------
  # Returns number of due verses
  # ----------------------------------------------------------------------------------------------------------
  def due_verses
    self.memverses.active.where("next_test <= ?", Date.today).count
  end

  # ----------------------------------------------------------------------------------------------------------
  # Returns number of due verse references
  # ----------------------------------------------------------------------------------------------------------
  def due_refs
    if self.all_refs
      return self.memverses.active.ref_due.count
    else
      return self.memverses.active.passage_start.ref_due.count
    end
  end

  # ----------------------------------------------------------------------------------------------------------
  # Returns first verse that is due today
  # ----------------------------------------------------------------------------------------------------------
  def first_verse_today
    mv = self.memverses.active.order("next_test ASC").first

    if mv && mv.due?
      return mv.first_verse_due_in_sequence
    else
      return nil
    end

  end

  # ----------------------------------------------------------------------------------------------------------
  # Returns upcoming verses that need to be tested today for this user
  #   strict = true  : return only the individual verses that are strictly due today
  #   strict = false : return verse sequences as likely to be tested (Get rid of this?)
  # ----------------------------------------------------------------------------------------------------------
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
	    # TODO: how should we sort the upcoming verses
	    # TODO: we should convert passages into Gen 1:1-10

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


  # ----------------------------------------------------------------------------------------------------------
  # Change reminder frequency for inactive users
  # ----------------------------------------------------------------------------------------------------------
  def update_reminder_freq

    last_reminded     = self.last_reminder || (Date.today - 100) # handles case where user has never been reminded
    last_activity     = self.last_activity_date || self.created_at.to_date # use created date if no activity ever
    reminder_freq     = self.reminder_freq
    days_since_active = (Date.today - last_activity).to_i

    # If any activity in last while then no need to update
    if reminder_freq == "Never" or days_since_active < 45
      return true  # don't change anything
    else

      if reminder_freq == "Quarterly" and days_since_active > 365
        logger.info("*** Changing reminder frequency for #{self.login} to an annual schedule. Last activity was #{days_since_active} days ago")
        self.update_column(:reminder_freq, "Annually")
      end

      if reminder_freq == "weekly" and days_since_active > 10  # focus on users who never set their reminder frequency
        logger.info("*** Changing reminder frequency for #{self.login} to a monthly schedule. Last activity was #{days_since_active} days ago")
        self.update_column(:reminder_freq, "Never")
      end

      if reminder_freq == "Weekly" and days_since_active > 40
        logger.info("*** Changing reminder frequency for #{self.login} to a monthly schedule. Last activity was #{days_since_active} days ago")
        self.update_column(:reminder_freq, "Monthly")
      end

      if reminder_freq == "Monthly" and days_since_active > 65
        logger.info("*** Changing reminder frequency for #{self.login} to a quarterly schedule. Last activity was #{days_since_active} days ago")
        self.update_column(:reminder_freq, "Quarterly")
      end

      if reminder_freq == "Daily" and days_since_active > 25
        logger.info("*** Changing reminder frequency for #{self.login} to a weekly schedule. Last activity was #{days_since_active} days ago")
        self.update_column(:reminder_freq, "Weekly")
      end
    end

  end

  # ----------------------------------------------------------------------------------------------------------
  # Check whether user needs reminder
  # Input: User object
  # ----------------------------------------------------------------------------------------------------------
  def needs_reminder?

    last_reminded = self.last_reminder || (Date.today - 100) # handles case where user has never been reminded

    # Count a login as a reminder if login is more recent than the reminder. This avoids the case where a user gets
    # a reminder the day after they've logged in when they only want weekly reminders
    if last_reminded < (self.last_activity_date || last_reminded)
      last_reminded = self.last_activity_date
    end

    mv = Memverse.find(:first, :conditions => ["user_id = ?", self.id], :order => "next_test ASC")

    if mv.nil? or self.reminder_freq == "Never"
      return false # users who don't have any memory verses need more than a reminder!
    elsif last_reminded + reminder_in_days(self.reminder_freq) < Date.today
      return ( mv.next_test + reminder_in_days(self.reminder_freq) < Date.today )
    else
      return false
    end
  end

  # ----------------------------------------------------------------------------------------------------------
  # Delete a user's account
  # ----------------------------------------------------------------------------------------------------------
  def delete_account

    # Remove user's memory verses
    user_mv = self.memverses
    Rails.logger.info("===== Removing user #{self.login} and his/her #{user_mv.length} memory verses =========")
    user_mv.each { |mv|
      logger.info("|  -- Deleting memory verse #{mv.id}")
      mv.destroy
    }

    # TODO: Potentially delete their church if they're the only member

    self.destroy

  end

  # ----------------------------------------------------------------------------------------------------------
  # Delete accounts of users that never added any verses
  # ----------------------------------------------------------------------------------------------------------
  def self.delete_users_who_never_started

    # TODO: What about pending verses? Is this method used?

    where("created_at < ?", 3.months.ago).where(learning: 0, memorized: 0).each { |u|
      # u.destroy
      Rails.logger.info("We should remove user #{u.login} - they haven't got started in over three months")
    }
  end


  # ----------------------------------------------------------------------------------------------------------
  # Unsubscribe from all email
  # ----------------------------------------------------------------------------------------------------------
  def unsubscribe
    self.newsletters    = false
    self.reminder_freq  = "Never"
    self.save # returns true if successfully saved
  end

  # ----------------------------------------------------------------------------------------------------------
  # Tweet about user
  # ----------------------------------------------------------------------------------------------------------
  def broadcast(news, importance)
    Tweet.create(news: "#{self} #{news}", user: self, importance: importance)
  end

  # ----------------------------------------------------------------------------------------------------------
  # User about to reach a milestone
  # ----------------------------------------------------------------------------------------------------------
  def reaching_milestone
    [9, 24, 49, 99, 199, 299, 499, 999, 1499, 1999, 2999, 3999, 4999, 9999].
    include?(self.memorized)
  end

  # ----------------------------------------------------------------------------------------------------------
  # Tweet about user reaching milestone
  # ----------------------------------------------------------------------------------------------------------
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

  # ----------------------------------------------------------------------------------------------------------
  # Return most difficult verse
  # Input: User object
  # Return: Verse object
  # ----------------------------------------------------------------------------------------------------------
  def most_difficult_vs

    mv = self.memverses.order("efactor ASC").first

    return nil if mv.nil? # user has no memory verses

    return mv
  end

  # ----------------------------------------------------------------------------------------------------------
  # Return random difficult verse
  # Input: User object
  # Return: Memverse object
  # ----------------------------------------------------------------------------------------------------------
  def random_verse

    mv = self.memverses.order("efactor ASC").limit(10).sample

    return nil if mv.nil? # user has no memory verses

    return mv
  end


  # ----------------------------------------------------------------------------------------------------------
  # Return time until next verse is due for review
  # Input: User object
  # Return: "today", "tomorrow", "in x days", "in more than a week", nil
  # ----------------------------------------------------------------------------------------------------------
  def next_verse_due

    mv = self.memverses.active.order("next_test ASC").first

    if mv.nil?
      return nil # users who have no active memory verses
    else
      days_to_next_review = (mv.next_test - Date.today).to_i

      return case days_to_next_review
        when 0      then "today"
        when 1      then "tomorrow"
        when 2..7   then "in " + days_to_next_review.to_s + " days"
        when 7..366 then "in more than a week"
        else             "in more than a week"
      end
    end
  end


  # ----------------------------------------------------------------------------------------------------------
  # Returns date of last activity for user -- only used during migration. Now handled with a counter cache
  # Activity can be either:
  #     - Testing a verse
  #     - Adding a new verse (not yet added)
  # ----------------------------------------------------------------------------------------------------------
  def init_activity_date
    mv = self.memverses.order("last_tested DESC").first
    if mv
      return mv.last_tested
    else
      return created_at.to_date # if user hasn't added verses then just use the day they signed up
    end
  end

  # ----------------------------------------------------------------------------------------------------------
  # User status
  # ----------------------------------------------------------------------------------------------------------
  def status
    self.is_active? ? "Active" : "Inactive"
  end

  # ----------------------------------------------------------------------------------------------------------
  # User has been active in last month
  # ----------------------------------------------------------------------------------------------------------
  def is_active?
    self.last_activity_date && self.last_activity_date > 1.month.ago.to_date
  end

  # ----------------------------------------------------------------------------------------------------------
  # User has not been active for two months or more
  # (remember, nil evaluates to false => a user who never activated will never be 'inactive')
  # ----------------------------------------------------------------------------------------------------------
  def is_inactive?
    self.last_activity_date && self.last_activity_date < 3.months.ago.to_date
  end
  # ----------------------------------------------------------------------------------------------------------
  # Check whether user needs reminder
  # Input: User object
  # ----------------------------------------------------------------------------------------------------------
  def needs_kick_in_pants?

    if self.has_started? or !self.confirmed_at  # user already has verses or never activated their account
      return false
    else
      if self.last_reminder.nil? and  days_since_contact_or_login > 1 # user has never been reminded
        Rails.logger.debug("*** #{self.login} has never been encouraged and two days have elapsed since registration")
        return true
      elsif days_since_contact_or_login > 31 # space reminders out by one month
        Rails.logger.debug("*** #{self.login} was last encouraged a month ago but still hasn't added a verse")
        return true
      else
        return false
      end
    end
  end

  # ----------------------------------------------------------------------------------------------------------
  # Has it been a week since the last reminder?
  # ----------------------------------------------------------------------------------------------------------
  def week_since_last_reminder?
    if self.last_reminder.nil?
      return true
    else
      return (Date.today - self.last_reminder) > 6
    end

  end

  # ----------------------------------------------------------------------------------------------------------
  # Return number of days since we last contacted user or they logged in
  # ----------------------------------------------------------------------------------------------------------
  def days_since_contact_or_login

    last_reminded = self.last_reminder || self.created_at.to_date
    last_login    = self.updated_at.to_date

    return [Date.today-last_reminded, Date.today-last_login].max.to_i

  end

  # ----------------------------------------------------------------------------------------------------------
  # Number of pending verses for user
  # TODO: Should this return a count (number) or all the Memverse objects?
  # ----------------------------------------------------------------------------------------------------------
  def pending
    self.memverses.inactive
  end

  # ----------------------------------------------------------------------------------------------------------
  # Returns top 200 users (sorted by number of verses memorized)
  # ----------------------------------------------------------------------------------------------------------
  def self.top_users
    User.active.order("memorized DESC").limit(250).select("id, login, name, created_at, church_id, country_id, memorized, learning, accuracy, ref_grade, level")
  end

  # ----------------------------------------------------------------------------------------------------------
  # Return hash of top referrers
  # ----------------------------------------------------------------------------------------------------------
  def self.top_referrers(numusers=50)
    leaderboard = Hash.new(0)

    active.find_each { |u| leaderboard[ u ] = u.referral_score }

    return leaderboard.sort{|a,b| a[1]<=>b[1]}.reverse[0...numusers]
  end

  # ----------------------------------------------------------------------------------------------------------
  # Fix verse linkage: set repair = true to fix problems
  # ----------------------------------------------------------------------------------------------------------
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

      # TODO: Need to fix first verse entry as well
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

  # ----------------------------------------------------------------------------------------------------------
  # Bloggity Settings
  # ----------------------------------------------------------------------------------------------------------
  def display_name
    self.name || self.login
  end

  # Whether a user can post to a given blog
  # Implement in your user model
  def can_blog?(blog_id = nil)
    # This can be implemented however you want, but here's how I would do it, if I were you and I had multiple blogs,
    # where some users were allowed to write in one set of blogs and other users were allowed to write in a different
    # set:
    # Create a string field in your user called something like "blog_permissions", and keep a Marshaled array of blogs
    # that this user is allowed to contribute to.  Ezra gives some details on how to save Marshaled data in Mysql here:
    # http://www.ruby-forum.com/topic/164786
    # To determine if the user is allowed to blog here, call up the array, and see if the blog_set_id
    # is contained in their list of allowable blogs.
    #
    # Of course, you could also create a join table to join users to blogs they can blog in.  But do you want to do
    # that with blog comments and ability to moderate comments as well?

    # Bloggers: Andy, Heather-Kate Taylor, Phil Walker, Dakota Lynch,
    # River La Belle, Alex Watt, Nathan Burkhalter, Josiah DeGraaf,
    # Bethany Meckle
    bloggers = [1, 2, 366, 1138, 3113, 4024, 3486, 4565, 2336, 15021]
    return bloggers.include?(self.id)
  end

  # Whether a user can moderate the comments for a given blog
  # Implement in your user model
  def can_moderate_blog_comments?(blog_id = nil)
    self.id == 1 or self.id == 2 or self.id == 3486
  end

  # Whether the comments that a user makes within a given blog are automatically approved (as opposed to being queued until a moderator approves them)
  # Implement in your user model, if you care.
  def blog_comment_auto_approved?(blog_id = nil)
    self.memverses.learning.count > 10  or self.completed_sessions >= 5
  end

  def can_comment?(blog_id = nil)
  	self.completed_sessions >= 2 # We need this to control the spammers
  end

  # Whether a user has access to create, edit and destroy blogs
  # Implement in your user model
  def can_modify_blogs?
    self.id == 1 or self.id == 2
  end

  # Implement in your user model
  def user_signed_in?
    true
  end

  # The path to your user's avatar.  Here we have sample code to fall back on a gravatar, if that's your bag.
  # Implement in your user model
  def blog_avatar_url
    if(self.respond_to?(:email))
      downcased_email_address = self.email.downcase
      hash = Digest::MD5::hexdigest(downcased_email_address)
      "https://www.gravatar.com/avatar/#{hash}?d=wavatar"
    else
      "https://www.pistonsforum.com/images/avatars/avatar22.gif"
    end
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
      else                 999  # just to be safe assume lengthy reminder interval on erroneous input
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
