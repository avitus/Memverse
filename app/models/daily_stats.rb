class DailyStats < ActiveRecord::Base

  # Structure
  # - Date [entry_date]
  # - Total number of users [users]
  #     - Active Users (last 30 days) [users_active_in_month]

  # - Total number of verses [verses]
  # - Total number of memory verses [memverses]
  #     - Memorized [memverses_learning]
  #     - Learning  [memverses_memorized]


  # Relationships


  # Validations
  validates_presence_of :entry_date

  # Named scopes
  scope :global,    -> { where(:segment => "Global") }
  scope :american,  -> { where(:segment => "United States") }

  # Capture Daily Stats
  def self.update
    # What do we want to save?
    # - Date [entry_date]
    # - Total number of users [users]
    #     - Active Users (last 30 days) [users_active_in_month]

    # - Total number of verses [verses]

    # - Total number of memory verses [memverses]
    #     - Memorized [memverses_learning]
    #     - Learning  [memverses_memorized]
    #     - Memorized and not overdue [memverses_memorized_not_overdue]
    #     - Learning and active in month [memverses_learning_active_in_month]

    # Check whether there is already an entry for today
    if !DailyStats.where("entry_date = ?", Date.today).exists?

      ds = DailyStats.new

      ds.entry_date                           = Date.today

      ds.users                                = User.count
      ds.users_active_in_month                = User.active.count

      ds.verses                               = Verse.count

      ds.memverses                            = Memverse.count
      ds.memverses_memorized                  = Memverse.memorized.count
      ds.memverses_learning                   = Memverse.learning.count

      ds.memverses_memorized_not_overdue      = Memverse.memorized.current.count
      ds.memverses_learning_active_in_month   = Memverse.learning.current.count

      ds.save

      # Save US data

      ds_us                                    = DailyStats.new
      ds_us.segment                            = "United States"

      ds_us.entry_date                         = Date.today

      ds_us.users                              = User.american.count
      ds_us.users_active_in_month              = User.american.active.count

      ds_us.verses                             = Verse.count

      ds_us.memverses                          = Memverse.american.count
      ds_us.memverses_memorized                = Memverse.american.memorized.count
      ds_us.memverses_learning                 = Memverse.american.learning.count

      ds_us.memverses_memorized_not_overdue    = Memverse.american.memorized.current.count
      ds_us.memverses_learning_active_in_month = Memverse.american.learning.current.count

      ds_us.save

    end

  end

  protected

end