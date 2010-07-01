#    t.string   "login",                     :limit => 40
#    t.string   "identity_url"
#    t.string   "name",                      :limit => 100, :default => ""
#    t.string   "email",                     :limit => 100
#    t.string   "crypted_password",          :limit => 40
#    t.string   "salt",                      :limit => 40
#    t.string   "remember_token",            :limit => 40
#    t.string   "activation_code",           :limit => 40
#    t.string   "state",                                    :default => "passive", :null => false
#    t.datetime "remember_token_expires_at"
#    t.datetime "activated_at"
#    t.datetime "deleted_at"
#    t.datetime "created_at"
#    t.datetime "updated_at"
#    t.date     "last_reminder"
#    t.string   "reminder_freq",                            :default => "weekly"
#    t.boolean  "newsletters",                              :default => true
#    t.string   "church"
#    t.integer  "church_id"
#    t.integer  "country_id"
#    t.string   "language",                                 :default => "English"
#    t.integer  "time_allocation",                          :default => 5
#    t.integer  "memorized",                                :default => 0
#    t.integer  "learning",                                 :default => 0
#    t.date     "last_activity_date"
#    t.boolean  "show_echo",                               :default => true

require 'digest/sha1'
require 'md5' # required for Gravatar support in Bloggity

class User < ActiveRecord::Base
  include Authentication
  include Authentication::ByPassword
  include Authentication::ByCookieToken
  include Authorization::AasmRoles

  # Validations
  validates_presence_of :login, :if => :not_using_openid?
  validates_length_of :login, :within => 3..40, :if => :not_using_openid?
  validates_uniqueness_of :login, :case_sensitive => false, :if => :not_using_openid?
  validates_format_of :login, :with => RE_LOGIN_OK, :message => MSG_LOGIN_BAD, :if => :not_using_openid?
  validates_format_of :name, :with => RE_NAME_OK, :message => MSG_NAME_BAD, :allow_nil => true
  validates_length_of :name, :maximum => 100
  validates_presence_of :email, :if => :not_using_openid?
  validates_length_of :email, :within => 6..100, :if => :not_using_openid?
  validates_uniqueness_of :email, :case_sensitive => false, :if => :not_using_openid?
  validates_format_of :email, :with => RE_EMAIL_OK, :message => MSG_EMAIL_BAD, :if => :not_using_openid?
  validates_uniqueness_of :identity_url, :unless => :not_using_openid?
  validate :normalize_identity_url
  
  # Relationships
  has_and_belongs_to_many :roles
  has_many                :memverses 
  has_many                :progress_reports
  has_many                :tweets
  belongs_to              :country,         :counter_cache => true
  belongs_to              :church,          :counter_cache => true
  belongs_to              :american_state,  :counter_cache => true
  
  # Record who tagged which verse
  acts_as_tagger
  
  # Associations for bloggity
  has_many :blog_posts
  has_many :blog_comments
  
  # Named Scopes
  named_scope :active,            lambda { {:conditions => ['last_activity_date >= ?', 1.month.ago ]} }
  named_scope :active_today,      lambda { {:conditions => ['last_activity_date = ?',  Date.today  ]} }
  named_scope :active_this_week,  lambda { {:conditions => ['last_activity_date >= ?', 1.week.ago  ]} }  
  named_scope :american,          :include => :country, :conditions => { 'countries.printable_name' => 'United States' }

  # HACK HACK HACK -- how to do attr_accessible from here?
  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here
  attr_accessible :login, :email, :name, :password, :password_confirmation, :identity_url, 
                  :newsletters, :reminder_freq, :last_reminder, :church, :country, :american_state, 
                  :show_echo, :max_interval, :mnemonic_use, :all_refs


  # Authenticates a user by their login name and unencrypted password - Returns the user or nil
  def self.authenticate(login, password)
    u = find_in_state :first, :active, :conditions => { :login => login } # need to get the salt
    u && u.authenticated?(password) ? u : nil
  end
  
  # Check if a user has a role
  def has_role?(role)
    list ||= self.roles.map(&:name)
    list.include?(role.to_s) || list.include?('admin')
  end
  
  # Not using open id
  def not_using_openid?
    identity_url.blank?
  end
  
  # Overwrite password_required for open id
  def password_required?
    new_record? ? not_using_openid? && (crypted_password.blank? || !password.blank?) : !password.blank?
  end
  
  
  # ----------------------------------------------------------------------------------------------------------
  # Check whether current user is memorizing a given verse in any translation
  # Input: "John", 3, 16
  # Output: mv object (if found) or nil (if not)
  # ----------------------------------------------------------------------------------------------------------     
  def has_verse?(book, chapter, versenum)
    
    book = "Psalms" if book == "Psalm" 
    self.memverses.first(:include => :verse, :conditions => {'verses.book' => book, 'verses.chapter' => chapter, 'verses.versenum' => versenum})

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
  # Check whether current user is memorizing a given verse (see also: 'has_verse' method above)
  # Input: verse_id
  # Returns: TRUE if user has verse in userlist else FALSE
  # ----------------------------------------------------------------------------------------------------------     
  def has_verse_id?(vs_id)
    ref = Memverse.find(:first, :conditions => ["user_id = ? and verse_id = ?", self, vs_id])
    return ref  
  end  

  # ----------------------------------------------------------------------------------------------------------
  # Check whether current user is memorizing a given verse in any translation
  # Input: User object
  # TODO: This method occasionally returns infinity due to test_interval being zero. This is not the best place
  #       to fix the problem but good enough hack for now.
  # ----------------------------------------------------------------------------------------------------------     
  def work_load
    time_per_verse = 1.0 # minutes
    verses_per_day = 2.0 # login, setup time etc
    self.memverses.each { |mv|
      if mv.test_interval == 0
        mv.test_interval = 1
        mv.save
      end
      verses_per_day += (1 / mv.test_interval.to_f) 
    }
    return (verses_per_day * time_per_verse).round 
  end
    
  # ----------------------------------------------------------------------------------------------------------
  # Check whether current user is memorizing any verses at all
  # Input: User object
  # ----------------------------------------------------------------------------------------------------------  
  def has_started?
    return self.memverses.length > 0
  end

  # ----------------------------------------------------------------------------------------------------------
  # Return hash of OT Verses memorized and learning
  # ----------------------------------------------------------------------------------------------------------   
  def ot_verses    
    { "Memorized" => self.memverses.memorized.old_testament.count, "Learning" => self.memverses.learning.old_testament.count }
  end

  # ----------------------------------------------------------------------------------------------------------
  # Return hash of NT Verses memorized and learning
  # ----------------------------------------------------------------------------------------------------------   
  def nt_verses    
    { "Memorized" => self.memverses.memorized.new_testament.count, "Learning" => self.memverses.learning.new_testament.count }
  end

  # ----------------------------------------------------------------------------------------------------------
  # Return hash of Histroy Verses memorized and learning
  # ----------------------------------------------------------------------------------------------------------   
  def history    
    { "Memorized" => self.memverses.memorized.history.count, "Learning" => self.memverses.learning.history.count }
  end
  
  # ----------------------------------------------------------------------------------------------------------
  # Return hash of Wisdom Verses memorized and learning
  # ----------------------------------------------------------------------------------------------------------   
  def wisdom    
    { "Memorized" => self.memverses.memorized.wisdom.count, "Learning" => self.memverses.learning.wisdom.count }
  end
  
  # ----------------------------------------------------------------------------------------------------------
  # Return hash of Prophecy Verses memorized and learning
  # ----------------------------------------------------------------------------------------------------------   
  def prophecy    
    { "Memorized" => self.memverses.memorized.prophecy.count, "Learning" => self.memverses.learning.prophecy.count }
  end
  
  # ----------------------------------------------------------------------------------------------------------
  # Return hash of Gospel Verses memorized and learning
  # ----------------------------------------------------------------------------------------------------------   
  def gospel    
    { "Memorized" => self.memverses.memorized.gospel.count, "Learning" => self.memverses.learning.gospel.count }
  end

  # ----------------------------------------------------------------------------------------------------------
  # Return hash of Epistle Verses memorized and learning
  # ----------------------------------------------------------------------------------------------------------   
  def epistle    
    { "Memorized" => self.memverses.memorized.epistle.count, "Learning" => self.memverses.learning.epistle.count }
  end

  # ----------------------------------------------------------------------------------------------------------
  # Has user ever finished a day of memorization
  # Input: User object
  # ----------------------------------------------------------------------------------------------------------
  def finished_a_mem_session?
    entries = ProgressReport.find( :first, 
                                   :conditions => ["user_id = ?", self.id])                          
    return !entries.nil?                             
  end


  # ----------------------------------------------------------------------------------------------------------
  # Returns list of complete chapters that user is memorizing
  # TODO: This needs serious opimization ... page load time for user with lots of complete books is 40 secs
  # ----------------------------------------------------------------------------------------------------------
  def complete_chapters
    
    cc = Array.new
    
    # Get all memory verses for user that are the first verse in a chapter
    start_mv = self.memverses.find(:all, :include => :verse, :conditions => { 'verses.versenum' => 1 })
    start_mv.sort!.each { |smv| 
      if smv.part_of_entire_chapter?
        if smv.chapter_memorized?
          cc << ["Complete", smv.verse.book + " " + smv.verse.chapter]
        else
          cc << ["Learning", smv.verse.book + " " + smv.verse.chapter]
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
    self.reminder_freq    = new_params["reminder_freq"]
    self.country          = Country.find(:first, :conditions => ["printable_name = ?", new_params["country"]])
    self.american_state   = AmericanState.find(:first, :conditions => ["name = ?", new_params["american_state"]])
    # If church doesn't exist in database we add it
    self.church           = Church.find(:first, :conditions => ["name = ?", new_params["church"]]) || Church.create(:name => new_params["church"])
    self.newsletters      = new_params["newsletters"]
    self.language         = new_params["language"]
    self.time_allocation  = new_params["time_allocation"]    
    self.show_echo        = new_params["show_echo"] 
    self.mnemonic_use     = new_params["mnemonic_use"] 
    self.all_refs         = new_params["all_refs"] 
    self.max_interval     = new_params["max_interval"] 
    self.save
  end

  # ----------------------------------------------------------------------------------------------------------
  # Returns number of overdue verses
  # Input: User object
  # ----------------------------------------------------------------------------------------------------------  
  def overdue_verses
    
    overdue_mv = 0
    
    # TODO: this should be done with a named search otherwise we bring back every memory verse
    self.memverses.each { |mv|
      if mv.next_test < Date.today
        overdue_mv += 1
      end
    }
 
    return overdue_mv
  end


  # ----------------------------------------------------------------------------------------------------------
  # Returns upcoming verses that need to be tested today for this user
  # Input:
  # Output: 
  # ----------------------------------------------------------------------------------------------------------  
  def upcoming_verses
    
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
      if reminder_freq == "weekly" and days_since_active > 10  # focus on users who never set their reminder frequency
        logger.info("*** Changing reminder frequency for #{self.login} to a monthly schedule. Last activity was #{days_since_active} days ago")
        self.reminder_freq = "Never"
        self.save
      end
      
      if reminder_freq == "Weekly" and days_since_active > 40
        logger.info("*** Changing reminder frequency for #{self.login} to a monthly schedule. Last activity was #{days_since_active} days ago")
        self.reminder_freq = "Monthly"
        self.save
      end
      
      if reminder_freq == "Monthly" and days_since_active > 65
        logger.info("*** Changing reminder frequency for #{self.login} to a quarterly schedule. Last activity was #{days_since_active} days ago")
        self.reminder_freq = "Quarterly"
        self.save
      end 
      
      if reminder_freq == "Daily" and days_since_active > 25
        logger.info("*** Changing reminder frequency for #{self.login} to a weekly schedule. Last activity was #{days_since_active} days ago")
        self.reminder_freq = "Weekly"
        self.save
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
    user_mv = Memverse.find(:all, :conditions => ["user_id = ?", self.id])
    logger.info("===== Removing user #{self.login} and his/her #{user_mv.length} memory verses =========")
    user_mv.each { |mv| 
      logger.info("|  -- Deleting memory verse #{mv.id}")
      mv.destroy 
    }
    
    # TODO: Potentially delete their church if they're the only member
    
    self.destroy    
    
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
  # User about to reach a milestone
  # ----------------------------------------------------------------------------------------------------------    
  def reaching_milestone
    [9, 19, 29, 39, 49, 99, 199, 299, 399, 499, 599, 699, 799, 899, 999, 1099, 1199, 1299, 1399, 1499, 1599, 1699, 1799, 1899, 1999, 9999].include?(self.memorized)
  end
  
  # ----------------------------------------------------------------------------------------------------------
  # Return most difficult verse
  # Input: User object
  # Return: Verse object
  # ---------------------------------------------------------------------------------------------------------- 
  def most_difficult_vs    
        
    mv = Memverse.find(:first, :conditions => ["user_id = ?", self.id], :order => "efactor ASC")
    if mv.nil?
      return nil # users who don't have any memory verses
    else
      return mv  
    end
  end    

  # ----------------------------------------------------------------------------------------------------------
  # Return random difficult verse
  # Input: User object
  # Return: Verse object
  # ---------------------------------------------------------------------------------------------------------- 
  def random_verse    
        
    mv = Memverse.find(:all, :conditions => ["user_id = ?", self.id], :order => "efactor ASC", :limit => 10).rand 
    if mv.nil?
      return nil # users who don't have any memory verses
    else
      return mv  
    end
  end      
  
  
  # ----------------------------------------------------------------------------------------------------------
  # Return time until next verse is due for review
  # Input: User object
  # Return: "today", "tomorrow", "in x days", "in more than a week", nil
  # ---------------------------------------------------------------------------------------------------------- 
  def next_verse_due    
        
    mv = Memverse.find(:first, :conditions => ["user_id = ?", self.id], :order => "next_test ASC")
    if mv.nil?
      return nil # users who don't have any memory verses
    else
      days_to_next_review = (mv.next_test - Date.today).to_i
      
      return case days_to_next_review
        when 0      then "today"
        when 1      then "tomorrow"
        when 2..7   then "in " + days_to_next_review.to_s + " days"
        when 7..366 then "in more than a week" 
        else             "today"
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
    mv = Memverse.find(:first, :select => "last_tested", :conditions => ["user_id = ?", self.id], :order => "last_tested DESC")    
    if mv
      return mv.last_tested
    else
      return nil
    end
  end


  # ----------------------------------------------------------------------------------------------------------
  # Check whether user activated their account
  # ----------------------------------------------------------------------------------------------------------   
  def never_activated?
    return self.state=="pending"
  end

  # ----------------------------------------------------------------------------------------------------------
  # User has been active in last month
  # ----------------------------------------------------------------------------------------------------------   
  def is_active?
    return self.last_activity_date > 1.month.ago.to_date
  end

  # ----------------------------------------------------------------------------------------------------------
  # User has not been active for two months or more
  # ---------------------------------------------------------------------------------------------------------- 
  def is_inactive?
    return self.last_activity_date < 3.months.ago.to_date
  end
  # ----------------------------------------------------------------------------------------------------------
  # Check whether user needs reminder
  # Input: User object
  # ---------------------------------------------------------------------------------------------------------- 
  def needs_kick_in_pants?   
    
    if self.has_started? or self.state=="pending"  # user already has verses or never activated their account
      return false
    else
      if self.last_reminder.nil? and  days_since_contact_or_login > 1 # user has never been reminded
        logger.debug("*** #{self.login} has never been encouraged and two days have elapsed since registration")
        return true        
      elsif days_since_contact_or_login > 31 # space reminders out by one month
        logger.debug("*** #{self.login} was last encouraged a month ago but still hasn't add a verse")        
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
    
    logger.debug("*** Returning #{[Date.today-last_reminded, Date.today-last_login].max.to_i} for user #{self.id}")
    return [Date.today-last_reminded, Date.today-last_login].max.to_i
    
  end
  
  # ----------------------------------------------------------------------------------------------------------
  # Number of verses a user has memorized -- REPLACED WITH COUNTER CACHE
  # ---------------------------------------------------------------------------------------------------------- 
  #  def memorized
  #    Memverse.count(:all, :conditions => ["user_id = ? and status = ?", self.id, "Memorized"])
  #  end  
  
  # ----------------------------------------------------------------------------------------------------------
  # Number of verses a user is learning -- REPLACED WITH COUNTER CACHE
  # ---------------------------------------------------------------------------------------------------------- 
  #  def learning
  #    Memverse.count(:all, :conditions => ["user_id = ? and status = ?", self.id, "Learning"])  
  #  end
  
  # ----------------------------------------------------------------------------------------------------------
  # Returns hash of top ten users (sorted by number of verses memorized)
  # TODO: Find a way to speed this up ... eager loading (?), cache number of verses memorized?
  # ---------------------------------------------------------------------------------------------------------- 
  def self.top_users(numusers=200)

    leaderboard = Hash.new(0)
    
    # TODO: Only bring back active users, who have verses memorized, and only select the columns we need
    all_users = self.active
    
    all_users.each { |u| leaderboard[ u ] = u.memorized }
    
    return leaderboard.sort{|a,b| a[1]<=>b[1]}.reverse[0...numusers]
    
  end 
 
  # ----------------------------------------------------------------------------------------------------------
  # Delete accounts of users that never added any verses
  # ----------------------------------------------------------------------------------------------------------  
  def self.delete_users_who_never_started
    
    find(:all, :conditions => [ "created_at < ? and learning = ? and memorized = ?", 3.months.ago, 0, 0 ]).each { |u|
      # u.destroy
      logger.info("We should remove user #{u.login} - they haven't got started in over three months")
    } 
  end
  
  # ----------------------------------------------------------------------------------------------------------
  # Fix verse linkage: set repair = true to fix problems
  # ----------------------------------------------------------------------------------------------------------    
  def fix_verse_linkage(repair = false)
    
    report = Array.new
    
    Memverse.find(:all, :conditions => ["user_id = ?", self.id]).each { |mv|
    
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
  # Bloggity
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
    self.id == 2 or self.id == 366 or self.id == 1138 # Restrict blogging to me, Heather-Kate Taylor and Phil Walker
  end
  
  # Whether a user can moderate the comments for a given blog
  # Implement in your user model
  def can_moderate_blog_comments?(blog_id = nil)
    self.id == 2 or self.memverses.memorized.count > 1000
  end
  
  # Whether the comments that a user makes within a given blog are automatically approved (as opposed to being queued until a moderator approves them)
  # Implement in your user model, if you care.
  def blog_comment_auto_approved?(blog_id = nil)
    self.id ==2 or self.memverses.memorized.count > 5
  end
  
  # Whether a user has access to create, edit and destroy blogs
  # Implement in your user model
  def can_modify_blogs?
    self.id == 2
  end
  
  # Implement in your user model 
  def logged_in?
    true
  end
  
  # The path to your user's avatar.  Here we have sample code to fall back on a gravatar, if that's your bag.
  # Implement in your user model 
  def blog_avatar_url
    if(self.respond_to?(:email))
      downcased_email_address = self.email.downcase
      hash = MD5::md5(downcased_email_address)
      "http://www.gravatar.com/avatar/#{hash}?d=wavatar"
    else
      "http://www.pistonsforum.com/images/avatars/avatar22.gif"
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
      when "Never"    then 365 # shouldn't get here
      else                 30  # just to be safe, assume monthly reminder interval on erroneous input
    end
  end
  
  def normalize_identity_url
    self.identity_url = OpenIdAuthentication.normalize_url(identity_url) unless not_using_openid?
  rescue URI::InvalidURIError
    errors.add_to_base("Invalid OpenID URL")
  end
  
end
