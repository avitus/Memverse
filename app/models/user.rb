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
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :confirmable, :validatable, 
         :encryptable, :encryptor => :restful_authentication_sha1
  
  # validates :login, :presence   => true,
                    # :uniqueness => { :case_sensitive => false },
                    # :length     => { :within => 3..40 }

  validates :name,  :length     => { :maximum => 100 },
                    :allow_nil  => true

  # "validatable" module of devise already handles email validation (was getting 2 error messages)
  # validates :email, :presence   => true,
  #                   :uniqueness => { :case_sensitive => false },
  #                   :length     => { :within => 6..100 }  
   
  # Relationships
  has_and_belongs_to_many :roles
  has_and_belongs_to_many :quests
  has_many                :memverses,         :dependent => :destroy 
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
  has_many :blog_posts, :foreign_key => "posted_by_id"
  has_many :blog_comments, :dependent => :destroy
  
  # Named Scopes
  scope :active,            lambda { where('last_activity_date >= ?', 1.month.ago) }
  scope :active_today,      lambda { where('last_activity_date = ?',  Date.today) }
  scope :active_this_week,  lambda { where('last_activity_date >= ?', 1.week.ago) }  
  scope :american,          where('countries.printable_name' => 'United States').includes(:country)
  scope :pending,           where(:confirmed_at => nil)

  # Setup accessible (or protected) attributes for your model
  # Prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here
  attr_accessible :login, :email, :name, :password, :password_confirmation, :identity_url, :remember_me,
                  :newsletters, :reminder_freq, :last_reminder, :church, :group, :country, :american_state, 
                  :show_echo, :max_interval, :mnemonic_use, :all_refs, :referred_by, :auto_work_load, :show_email
  
    
  # Check if a user has a role
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
    self.memverses.active.find_each { |mv|
      if mv.test_interval == 0
        mv.test_interval = 1
        mv.save
      end
      verses_per_day += (1 / mv.test_interval.to_f) 
    }
    return (verses_per_day * time_per_verse).round 
  end

  # ----------------------------------------------------------------------------------------------------------
  # User progression
  # ----------------------------------------------------------------------------------------------------------    
  def progression
    if completed_sessions >= 3
      return { :level => '6 - Onwards', :active => is_active? }
    elsif completed_sessions == 2
      return { :level => '5 - Returning User', :active => is_active? }
    elsif completed_sessions == 1
      return { :level => '4 - One Session Wonder', :active => is_active? }
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
	  		verses_activated = Array.new
	  		pending_verses = self.memverses.inactive.order("created_at ASC").limit(time_shortfall)
	  		pending_verses.each { |pv|
	  			pv.status    = pv.test_interval > 30 ? "Memorized" : "Learning"
	  			if pv.next_test <= Date.today
	  			  pv.next_test = Date.today + 1
	  			end
	  			pv.save
	  			verses_activated << pv
	  		}
	  		return verses_activated
	  	end
	  	
	  end
	  
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
	  return case time_period
	    when :week  then self.progress_reports.where('entry_date > ?', 1.week.ago).count
	    when :month then self.progress_reports.where('entry_date > ?', 1.month.ago).count
	    when :year  then self.progress_reports.where('entry_date > ?', 1.year.ago).count
	    when :total then self.progress_reports.count
	    else self.progress_reports.count
	  end  
	end

  # ----------------------------------------------------------------------------------------------------------
  # Return hash of OT Verses memorized and learning
  # ----------------------------------------------------------------------------------------------------------   
  def ot_verses    
    { "Memorized" => self.memverses.memorized.old_testament.count, "Learning" => self.memverses.learning.old_testament.count }
  end
  
  def ot_perc
    self.has_active? ? (self.memverses.active.old_testament.count.to_f / self.memverses.active.count.to_f * 100).round : 0
  end

  # ----------------------------------------------------------------------------------------------------------
  # Return hash of NT Verses memorized and learning
  # ----------------------------------------------------------------------------------------------------------   
  def nt_verses    
    { "Memorized" => self.memverses.memorized.new_testament.count, "Learning" => self.memverses.learning.new_testament.count }
  end

  def nt_perc
    self.has_active? ? (self.memverses.active.new_testament.count.to_f / self.memverses.active.count.to_f * 100).round : 0
  end

  # ----------------------------------------------------------------------------------------------------------
  # Return hash of Histroy Verses memorized and learning
  # ----------------------------------------------------------------------------------------------------------   
  def history    
    { "Memorized" => self.memverses.memorized.history.count, "Learning" => self.memverses.learning.history.count }
  end
  
  def h_perc
    self.has_active? ? (self.memverses.active.history.count.to_f / self.memverses.active.count.to_f * 100).round : 0
  end  
  
  # ----------------------------------------------------------------------------------------------------------
  # Return hash of Wisdom Verses memorized and learning
  # ----------------------------------------------------------------------------------------------------------   
  def wisdom    
    { "Memorized" => self.memverses.memorized.wisdom.count, "Learning" => self.memverses.learning.wisdom.count }
  end
  
  def w_perc
    self.has_active? ? (self.memverses.active.wisdom.count.to_f / self.memverses.active.count.to_f * 100).round : 0
  end    
  
  # ----------------------------------------------------------------------------------------------------------
  # Return hash of Prophecy Verses memorized and learning
  # ----------------------------------------------------------------------------------------------------------   
  def prophecy    
    { "Memorized" => self.memverses.memorized.prophecy.count, "Learning" => self.memverses.learning.prophecy.count }
  end
  
  def p_perc
    self.has_active? ? (self.memverses.active.prophecy.count.to_f / self.memverses.active.count.to_f * 100).round : 0
  end    
  
  # ----------------------------------------------------------------------------------------------------------
  # Return hash of Gospel Verses memorized and learning
  # ----------------------------------------------------------------------------------------------------------   
  def gospel    
    { "Memorized" => self.memverses.memorized.gospel.count, "Learning" => self.memverses.learning.gospel.count }
  end

  def g_perc
    self.has_active? ? (self.memverses.active.gospel.count.to_f / self.memverses.active.count.to_f * 100).round : 0
  end  

  # ----------------------------------------------------------------------------------------------------------
  # Return hash of Epistle Verses memorized and learning
  # ----------------------------------------------------------------------------------------------------------   
  def epistle    
    { "Memorized" => self.memverses.memorized.epistle.count, "Learning" => self.memverses.learning.epistle.count }
  end

  def e_perc
    self.has_active? ? (self.memverses.active.epistle.count.to_f / self.memverses.active.count.to_f * 100).round : 0
  end  

  # ----------------------------------------------------------------------------------------------------------
  # Returns all quests still needed for user's current level
  # ----------------------------------------------------------------------------------------------------------   
  def current_uncompleted_quests
    Quest.where(:level => self.level+1) - self.current_completed_quests
  end

  # ----------------------------------------------------------------------------------------------------------
  # Returns all quests completed for user's current level
  # ----------------------------------------------------------------------------------------------------------  
  def current_completed_quests
    self.quests.where(:level => self.level+1)
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
    
    # TODO: Can remove this if sure that no users have a nil level field
    if self.level.nil?
      self.level = 0
    end
    
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
  # Save Entry in Progress Table
  # ----------------------------------------------------------------------------------------------------------
  def save_progress_report
    
    # Check whether there is already an entry for today
    pr = ProgressReport.find(:first, :conditions => { :user_id => self.id, :entry_date => Date.today} )    
    
    if pr.nil?
    
      pr = ProgressReport.new
      
      pr.user_id          = self.id
      pr.entry_date       = Date.today
      pr.memorized        = self.memorized
      pr.learning         = self.learning
      pr.time_allocation  = self.work_load
      
      pr.save
      
    end
  end

  # ----------------------------------------------------------------------------------------------------------
  # Return list of people a user has referred
  # ----------------------------------------------------------------------------------------------------------  
  def referrals( active = false )
    if active
      User.active.find(:all, :conditions => { :referred_by => self.id })
    else
      User.find(:all, :conditions => { :referred_by => self.id })
    end
  end

  # ----------------------------------------------------------------------------------------------------------
  # Return number of people a user has referred
  # ----------------------------------------------------------------------------------------------------------  
  def num_referrals( active = false )
    self.referrals(active).length
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
  # Number of tags a user has applied
  # ----------------------------------------------------------------------------------------------------------  
  def num_taggings
    ActsAsTaggableOn::Tagging.find(:all, :conditions => {:tagger_type => "user", :tagger_id => self.id}).length
  end

  # ----------------------------------------------------------------------------------------------------------
  # Returns list of complete chapters that user is memorizing
  # TODO: This needs serious optimization ... page load time for user with lots of complete books is 40 secs
  # ----------------------------------------------------------------------------------------------------------
  def complete_chapters
    
    cc = Array.new
    
    # Get all memory verses for user that are the first verse in a chapter
    start_mv = self.memverses.includes(:verse).where('verses.versenum' => 1)
    start_mv.sort!.each { |smv| 
      if smv.part_of_entire_chapter?
        if smv.chapter_memorized?
          cc << ["Memorized", smv.verse.book + " " + smv.verse.chapter.to_s]
        else
          cc << ["Learning", smv.verse.book + " " + smv.verse.chapter.to_s]
          # TODO: What should we do about "Pending" chapters?
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
    self.country          = Country.find(:first, :conditions => ["printable_name = ?", new_params["country"]])
    self.american_state   = AmericanState.find(:first, :conditions => ["name = ?", new_params["american_state"]])
    # If church, group doesn't exist in database we add it
    self.church           = Church.find(:first, :conditions => ["name = ?", new_params["church"]]) || Church.create(:name => new_params["church"])
    self.group            = Group.find(:first, :conditions => ["name = ?", new_params["group"]]) || Group.create(:name => new_params["group"])
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
  # ----------------------------------------------------------------------------------------------------------
	def reset_memorization_schedule
		
		load_target		 = self.work_load
		load_for_today = Memverse.active.where("user_id = ? and next_test <= ?", self.id, Date.today).order("next_test ASC" )
																		
		load_for_today.each_with_index { |mv, index|
			mv.next_test = Date.today + (index / load_target)
			mv.save
		}
		
		return due_verses
		
		# extend future verses if necessary
		# TODO: call a generic load smoothing function to space out verses evenly. Might not be worth doing given that 
		# each day's memorization session changes the future load
		
	end

  # ----------------------------------------------------------------------------------------------------------
  # Returns number of overdue verses (does not include verses that are due today)
  # ----------------------------------------------------------------------------------------------------------  
  def overdue_verses
    Memverse.active.where("user_id = ? and next_test < ?", self.id, Date.today).count    
  end

  # ----------------------------------------------------------------------------------------------------------
  # Returns number of due verses
  # ----------------------------------------------------------------------------------------------------------
  def due_verses
    Memverse.active.where("user_id = ? and next_test <= ?", self.id, Date.today).count  
  end

  # ----------------------------------------------------------------------------------------------------------
  # Returns first verse that is due today
  # ---------------------------------------------------------------------------------------------------------- 
  def first_verse_today
    # mv = Memverse.find( :first, :conditions => {:user_id => self.id}, :order => "next_test ASC")
    mv = Memverse.where(:user_id => self.id).active.order("next_test ASC").first()
    
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
  		# upcoming = Memverse.find(:all, :conditions => ["user_id = ? and next_test <= ?", self, Date.today], :order => "next_test ASC" )
  		upcoming = Memverse.active.where("user_id = ? and next_test <= ?", self, Date.today).order("next_test ASC")
  	else  
	    # mvs = Memverse.find(:all, :conditions => ["user_id = ? and next_test <= ?", self, Date.today], :order => "next_test ASC", :limit => limit)
	    mvs = Memverse.active.where("user_id = ? and next_test <= ?", self, Date.today).order("next_test ASC").limit(limit)
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
	    
	        upcoming << mv unless mv.prior_in_passage_to?(current_mv)
	        
	        # Add any subsequent verses in the chain
	        next_verse = mv.next_verse
	        if next_verse  
	          cmv = Memverse.find( next_verse )
	        end
	        while (next_verse) and cmv.more_to_memorize_in_sequence?
	          cmv         = Memverse.find(next_verse)          
	          upcoming   << cmv unless cmv.prior_in_passage_to?(current_mv)
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
    
    find(:all, :conditions => [ "created_at < ? and learning = ? and memorized = ?", 3.months.ago, 0, 0 ]).each { |u|
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
  # User about to reach a milestone
  # ----------------------------------------------------------------------------------------------------------    
  def reaching_milestone
    [9, 19, 29, 39, 49, 99, 199, 299, 399, 499, 599, 699, 799, 899, 999, 1099, 1199, 1299, 1399, 1499, 1599, 1699, 1799, 1899, 1999, 2499, 2999, 3999].include?(self.memorized)
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
        
    mv = Memverse.find(:all, :conditions => ["user_id = ?", self.id], :order => "efactor ASC", :limit => 10).sample 
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
        
    mv = Memverse.find(:first, :conditions => ["user_id = ? AND status != ?", self.id, "Pending"], :order => "next_test ASC")
    if mv.nil?
      return nil # users who don't have any memory verses
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
    mv = Memverse.find(:first, :select => "last_tested", :conditions => ["user_id = ?", self.id], :order => "last_tested DESC")    
    if mv
      return mv.last_tested
    else
      return nil
    end
  end

  # ----------------------------------------------------------------------------------------------------------
  # User status
  # ----------------------------------------------------------------------------------------------------------   
  def status
    return self.is_active? ? "Active" : "Inactive"
  end

  # ----------------------------------------------------------------------------------------------------------
  # User has been active in last month
  # ----------------------------------------------------------------------------------------------------------   
  def is_active?
    return self.last_activity_date && self.last_activity_date > 1.month.ago.to_date
  end

  # ----------------------------------------------------------------------------------------------------------
  # User has not been active for two months or more 
  # (remember, nil evaluates to false => a user who never activated will never be 'inactive')
  # ---------------------------------------------------------------------------------------------------------- 
  def is_inactive?
    return self.last_activity_date && self.last_activity_date < 3.months.ago.to_date
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
  # ----------------------------------------------------------------------------------------------------------   
  def pending
    Memverse.count(:all, :conditions => ["user_id = ? and status = ?", self.id, "Pending"])
  end
  
  # ----------------------------------------------------------------------------------------------------------
  # Returns top 200 users (sorted by number of verses memorized)
  # ---------------------------------------------------------------------------------------------------------- 
  def self.top_users    
    User.active.order("memorized DESC").limit(200).select("id, login, name, created_at, church, church_id, country_id, memorized, learning, accuracy, ref_grade, level")
  end 
  
  # ----------------------------------------------------------------------------------------------------------
  # Return hash of top referrers
  # ----------------------------------------------------------------------------------------------------------   
  def self.top_referrers(numusers=50)
    leaderboard = Hash.new(0)
    
    active.find_each { |u|
    	
      referral_score = u.num_referrals(active=true).to_f
      u.referrals(active=true).each { |r|
        referral_score += r.num_referrals(active=true)/2.to_f
      }
      
      leaderboard[ u ] = referral_score    	
    }

    return leaderboard.sort{|a,b| a[1]<=>b[1]}.reverse[0...numusers]
  end
  
  # ----------------------------------------------------------------------------------------------------------
  # Fix verse linkage: set repair = true to fix problems
  # ----------------------------------------------------------------------------------------------------------    
  def fix_verse_linkage(repair = false)
    
    report = Array.new
    
    Memverse.where(:user_id => self.id).find_each { |mv|
    
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
    self.id == 2 or self.id == 366 or self.id == 1138 or self.id == 3113 or self.id == 4024 or self.id == 3486 or self.id == 4565 # Restrict blogging to me, Heather-Kate Taylor, Phil Walker, Dakota Lynch, River La Belle, Alex Watt and Nathan Burkhalter
  end
  
  # Whether a user can moderate the comments for a given blog
  # Implement in your user model
  def can_moderate_blog_comments?(blog_id = nil)
    self.id == 2 or self.id == 3486
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
    self.id == 2
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
  
  def generate_login
    if !self.login?
      login = self.name.parameterize
	  x = 0
	  while User.find_by_login(login) do
	    x += 1
	    login = self.name.parameterize + "--" + x.to_s
	  end
	  self.login = login
	end
  end
  
end
