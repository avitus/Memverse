class ChartController < ApplicationController

  before_action :authenticate_user!, :except => :load_memverse_clock

  # ----------------------------------------------------------------------------------------------------------
  # Stacked bar chart to show user progress
  # ----------------------------------------------------------------------------------------------------------
  def load_progress

    chart_data = Array.new
    # Set up data series
    y_learning  = Array.new
    y_memorized = Array.new
    y_time      = Array.new
    x_date      = Array.new

    # Get progress entries for specified user or current user
    if params[:user]
      user_id = params[:user]
    else
      user_id = current_user.id
    end

    all_entries = ProgressReport.where(:user_id => user_id).order('entry_date')
    
    # TODO: Consider deleting extra entries periodically
    # TODO: Add in last entry so that graph always shows current day
    # 'every' method is defined in /config/intializers/activerecord_extensions
    # ALV [Mar 2018] This is far, far too slow.
    #   entries = all_entries.length > 160 ? all_entries.every( all_entries.length / 80 ) : all_entries
    entries = all_entries

    if !entries.empty?
      # Build data series
      entries.each { |entry|
        y_learning  << entry.learning
        y_memorized << entry.memorized
        y_time      << entry.time_allocation
        x_date      << entry.entry_date.to_s
      }
    else
        y_learning  << 0
        y_memorized << 0
        y_time      << 0
        x_date      << Date.today.to_s
    end

    chart_data << y_learning
    chart_data << y_memorized
    chart_data << y_time
    chart_data << x_date

    respond_to do |format|
      format.json { render json: chart_data }
    end
  end

  # ----------------------------------------------------------------------------------------------------------
  # Chart Showing User Consistency
  # ----------------------------------------------------------------------------------------------------------
  def load_consistency_progress

    chart_data = Array.new
    # Set up data series
    y_consistency       = Array.new
    x_consistency_date  = Array.new

    # Get progress entries for specified user or current user
    if params[:user]
      user_id = params[:user]
    else
      user_id = current_user.id
    end
    
    all_entries = ProgressReport.where(:user_id => user_id).order('entry_date')
    
    # TODO: Consider deleting extra entries periodically
    # TODO: Add in last entry so that graph always shows current day
    # entries = all_entries.length > 160 ? all_entries.every( all_entries.length / 80 ) : all_entries
    entries = all_entries
   
    if !entries.empty?
      # Build data series
      entries.each { |entry|
        y_consistency           << entry.consistency
        x_consistency_date      << entry.entry_date.to_s
      }
    else
        y_consistency      << 0
        x_consistency_date << Date.today.to_s
    end

    chart_data << y_consistency
    chart_data << x_consistency_date

    respond_to do |format|
      format.json { render json: chart_data }
    end
  end


  # ----------------------------------------------------------------------------------------------------------
  # Chart Showing Total Users and Memory Verses
  # ----------------------------------------------------------------------------------------------------------
  def global_data

    chart_data = Array.new
    # Set up data series
    y_learning  = Array.new
    y_memorized = Array.new
    y_users     = Array.new
    x_date      = Array.new

    # Get daily statistics and build data series
    all_entries = DailyStats.where(:segment => "Global")

    # TODO: Consider deleting extra entries periodically
    # TODO: Add in last entry so that graph always shows current day
    # entries = all_entries.length > 160 ? all_entries.every( all_entries.length / 80 ) : all_entries
    entries = all_entries

    entries.each { |entry|
      y_learning  << entry.memverses_learning
      y_memorized << entry.memverses_memorized
      y_users     << entry.users_active_in_month
      x_date      << entry.entry_date.to_s
    }

    chart_data << y_learning
    chart_data << y_memorized
    chart_data << y_users
    chart_data << x_date

    respond_to do |format|
      format.json { render json: chart_data }
    end

  end

end

