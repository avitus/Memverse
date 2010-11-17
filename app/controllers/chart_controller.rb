class Array
  def every(n)
    select {|x| index(x) % n == 0}
  end
end


class ChartController < ApplicationController

  before_filter :login_required, :except => :load_memverse_clock

  helper Ziya::HtmlHelpers::Charts
  helper Ziya::YamlHelpers::Charts

  # Callback from the flash movie to get the chart's data
  # Uses line_chart.yml for style

  # ----------------------------------------------------------------------------------------------------------
  # Stacked bar chart to show user progress
  # ----------------------------------------------------------------------------------------------------------
  def load_progress
    
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

    all_entries = ProgressReport.find( :all, :conditions => { :user_id => user_id }) 
    
    # TODO: Consider deleting extra entries periodically
    # TODO: Add in last entry so that graph always shows current day
    entries = all_entries.length > 160 ? all_entries.every( all_entries.length / 80 ) : all_entries
    
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
        
    # Create graph 
    chart = Ziya::Charts::Mixed.new('JTA-A16M--GO.945CWK-2XOI1X0-7L', 'stacked_column_chart') # args: license key, chart name
    chart.add :chart_types, %w[column column line]

    # X-Axis
    chart.add( :axis_category_text, x_date )

    # Space out the labels on the x-axis. A zero value doesn't hide any labels. 
    # If the skip value is 1, then the first label is displayed, the following label is skipped, and so on. 
    # If the skip value is 2, then the first label is displayed, the following 2 are skipped, and so on.
    skip = x_date.length / 14 # Show max of 16 data labels
    chart.add( :user_data, :skip, skip )
    
    # Secondary Axis Labels
    max_time            = y_time.compact.max # first remove nil's
    min_time            = y_time.compact.min # first remove nil's
    time_axis_interval  = (max_time.to_f / 7).ceil  # There are 8 division on vertical axis, divide by two less to favor bottom part of graph
    
    # Calculate ratio between two axes
    secondary_axis_max  = time_axis_interval * 8 # <--- this 8 is the number of divisions on the axis
    primary_axis_max    = vertical_axis_max( (y_learning + y_memorized).max ) # find maximum element from either series  
    
    # Scale secondary y-axis (time_allocation)
    y_time.collect! { |t|
      if !t.nil?
        (t.to_f * primary_axis_max.to_f / secondary_axis_max.to_f)
      end
    }
    
    # Y-Axis
    chart.add( :series, "Memorized",  y_memorized )
    chart.add( :series, "Learning",   y_learning  )
    chart.add( :series, "Mins / Day", y_time      )
    
    chart.add( :user_data, :secondary_y_interval, time_axis_interval )
    
    # Theme
    chart.add( :theme , "memverse" )  
    
    respond_to do |fmt|
      fmt.xml { render :xml => chart.to_xml }
    end
  end   


  # ----------------------------------------------------------------------------------------------------------
  # Chart Showing Total Users and Memory Verses
  # ----------------------------------------------------------------------------------------------------------  
  def load_memverse_clock
    # Set up data series
    y_learning  = Array.new
    y_memorized = Array.new
    y_users     = Array.new
    x_date      = Array.new    
    
    # Get daily statistics and build data series
    all_entries = DailyStats.find(:all, :conditions => {:segment => "Global"})
     
    # TODO: Consider deleting extra entries periodically
    # TODO: Add in last entry so that graph always shows current day
    entries = all_entries.length > 160 ? all_entries.every( all_entries.length / 80 ) : all_entries        
  
    entries.each { |entry|
      y_learning  << entry.memverses_learning
      y_memorized << entry.memverses_memorized
      y_users     << entry.users_active_in_month
      x_date      << entry.entry_date.to_s
    }     
                
    # Create graph 
    chart = Ziya::Charts::Mixed.new('JTA-A16M--GO.945CWK-2XOI1X0-7L', 'memverse_clock_chart') # args: license key, chart name
    chart.add :chart_types, %w[column column line]

    # X-Axis
    chart.add( :axis_category_text, x_date )

    # Space out the labels on the x-axis. A zero value doesn't hide any labels. 
    # If the skip value is 1, then the first label is displayed, the following label is skipped, and so on. 
    # If the skip value is 2, then the first label is displayed, the following 2 are skipped, and so on.
    skip = x_date.length / 14 # Show max of 16 data labels
    chart.add( :user_data, :skip, skip )
    
    # Secondary Axis Labels
    max_users           = y_users.compact.max # first remove nil's
    min_users           = y_users.compact.min # first remove nil's
    user_axis_interval  = (max_users.to_f / 7).ceil  # There are 8 division on vertical axis, divide by two less to favor bottom part of graph
    
    # Calculate ratio between two axes
    secondary_axis_max  = user_axis_interval * 8 # <--- this 8 is the number of divisions on the axis
    primary_axis_max    = vertical_axis_max( (y_learning + y_memorized).max ) # find maximum element from either series
    
    # Scale secondary y-axis (time_allocation)
    y_users.collect! { |t|
      if !t.nil?
        (t.to_f * primary_axis_max.to_f / secondary_axis_max.to_f).to_i
      end
    }
    
    # Y-Axis
    chart.add( :series, "Memorized",    y_memorized )
    chart.add( :series, "Learning",     y_learning  )
    chart.add( :series, "Active Users", y_users      )
    
    chart.add( :user_data, :secondary_y_interval, user_axis_interval )
    
    # Theme
    chart.add( :theme , "memverse" )  
    
    respond_to do |fmt|
      fmt.xml { render :xml => chart.to_xml }
    end

  end # load_memverse_clock
  
  # ----------------------------------------------------------------------------------------------------------
  # Chart Showing Total Users and Memory Verses
  # ----------------------------------------------------------------------------------------------------------  
  
  def vertical_axis_max( maxval )
    case maxval
      when     0..    7  then     8 # Interval per division =    1
      when     8..   15  then    16 # Interval per division =    2
      when    16..   23  then    24 # Interval per division =    3
      when    24..   31  then    32 # Interval per division =    4
      when    32..   39  then    40 # Interval per division =    5
      when    40..   47  then    48 # Interval per division =    6
      when    48..   55  then    56 # Interval per division =    7
      when    56..   63  then    64 # Interval per division =    8
      when    64..   79  then    80 # Interval per division =   10
      when    80..  159  then   160 # Interval per division =   20
      when   160..  239  then   240 # Interval per division =   30
      when   240..  319  then   320 # Interval per division =   30
      when   320..  399  then   400 # Interval per division =   30
      when   400..  479  then   480 # Interval per division =   30
      when  8000..15999  then 16000 # Interval per division = 2000
      when 16000..23999  then 24000 # Interval per division = 3000      
      when 24000..31999  then 32000 # Interval per division = 3000      
      when 32000..39999  then 40000 # Interval per division = 3000      
      when 40000..47999  then 48000 # Interval per division = 3000      
      when 48000..55999  then 56000 # Interval per division = 3000      
      else                     320  # Interval per division =  ?
    end
  end

end
