require 'csv'

class Admin::OnboardingDashboardController < ApplicationController
  layout 'application'
  before_action :authenticate_admin!
  
  def index
    # Set date range (default to past 2 weeks)
    @date_range = if params[:date_range].present?
                    params[:date_range].to_i.days.ago..Time.current
                  else
                    14.days.ago..Time.current
                  end
    
    # Get new users in date range with necessary associations
    @new_users = User.where(created_at: @date_range)
                     .includes(:memverses, :country, :american_state, :group, :church, :progress_reports)
    
    # Apply filters
    @new_users = apply_filters(@new_users)
    
    # Apply ordering after filters
    @new_users = @new_users.order(created_at: :desc)
    
    # Calculate aggregate metrics
    @metrics = calculate_onboarding_metrics(@new_users)
    
    # Calculate previous period metrics for comparison
    previous_range = (28.days.ago..14.days.ago)
    previous_users = User.where(created_at: previous_range)
    @previous_metrics = calculate_onboarding_metrics(previous_users)
    
    # Prepare chart data
    @chart_data = prepare_chart_data(@new_users)
    
    # Paginate for table display
    @users_paginated = @new_users.page(params[:page]).per(25)
    
    respond_to do |format|
      format.html
      format.csv { send_data generate_csv(@new_users), filename: "onboarding_report_#{Date.current}.csv" }
    end
  end
  
  def show
    @user = User.find(params[:id])
    @memverses = @user.memverses.includes(:verse).order(created_at: :desc).limit(10)
    @progress_reports = @user.progress_reports.order(entry_date: :desc).limit(10)
  end
  
  def email_unengaged
    # Get users from past 14 days who are confirmed
    recent_users = User.where(created_at: 14.days.ago..Time.current)
                       .where.not(confirmed_at: nil)
                       .to_a
    
    # Filter for unengaged users (progression < 3)
    unengaged_users = recent_users.select { |u| u.progression < 3 }
    
    unengaged_users.each do |user|
      UserMailer.onboarding_reminder(user).deliver_later
    end
    
    flash[:success] = "Reminder emails sent to #{unengaged_users.count} unengaged users"
    redirect_to admin_onboarding_dashboard_index_path
  end
  
  private
  
  def authenticate_admin!
    unless current_user&.admin?
      flash[:error] = 'You must be an admin to access this page'
      redirect_to root_path
    end
  end
  
  def apply_filters(users)
    # Filter by progression level (progression is a method, not a column, so we filter in memory)
    if params[:progression_level].present?
      users_array = users.to_a
      filtered_users = case params[:progression_level]
                      when 'not_started'
                        users_array.select { |u| u.progression <= 1 }
                      when 'activated'
                        users_array.select { |u| u.progression == 2 }
                      when 'getting_started'
                        users_array.select { |u| (3..4).include?(u.progression) }
                      when 'engaged'
                        users_array.select { |u| (5..6).include?(u.progression) }
                      when 'active'
                        users_array.select { |u| (7..8).include?(u.progression) }
                      when 'successful'
                        users_array.select { |u| u.progression == 9 }
                      else
                        users_array
                      end
      users = User.where(id: filtered_users.map(&:id))
    end
    
    # Filter by email confirmation status
    if params[:email_status].present?
      users = case params[:email_status]
              when 'confirmed'
                users.where.not(confirmed_at: nil)
              when 'unconfirmed'
                users.where(confirmed_at: nil)
              else
                users
              end
    end
    
    # Filter by activity status
    if params[:activity_status].present?
      users = case params[:activity_status]
              when 'active'
                users.where('last_activity_date >= ?', 7.days.ago)
              when 'recently_active'
                users.where(last_activity_date: 30.days.ago..7.days.ago)
              when 'inactive'
                users.where('last_activity_date < ? OR last_activity_date IS NULL', 30.days.ago)
              else
                users
              end
    end
    
    # Filter by translation set
    if params[:translation_status].present?
      users = case params[:translation_status]
              when 'set'
                users.where.not(translation: [nil, ''])
              when 'not_set'
                users.where(translation: [nil, ''])
              else
                users
              end
    end
    
    users
  end
  
  def calculate_onboarding_metrics(users)
    total = users.count
    return default_metrics if total == 0
    
    {
      total_users: total,
      activated: users.where.not(confirmed_at: nil).count,
      activation_rate: (users.where.not(confirmed_at: nil).count.to_f / total * 100).round(1),
      added_verses: users.joins(:memverses).distinct.count,
      engagement_rate: (users.joins(:memverses).distinct.count.to_f / total * 100).round(1),
      memorized_any: users.where('memorized > 0').count,
      memorization_rate: (users.where('memorized > 0').count.to_f / total * 100).round(1),
      still_active: users.where('last_activity_date >= ?', 7.days.ago).count,
      retention_rate_7d: calculate_retention_rate(users, 7),
      retention_rate_14d: calculate_retention_rate(users, 14),
      avg_verses_added: users.joins(:memverses).group('users.id').count.values.sum.to_f / [users.joins(:memverses).distinct.count, 1].max,
      avg_progression: calculate_avg_progression(users)
    }
  end
  
  def default_metrics
    {
      total_users: 0,
      activated: 0,
      activation_rate: 0,
      added_verses: 0,
      engagement_rate: 0,
      memorized_any: 0,
      memorization_rate: 0,
      still_active: 0,
      retention_rate_7d: 0,
      retention_rate_14d: 0,
      avg_verses_added: 0,
      avg_progression: 0
    }
  end
  
  def calculate_retention_rate(users, days)
    eligible_users = users.where('created_at <= ?', days.days.ago)
    return 0 if eligible_users.count == 0
    
    active_after_days = eligible_users.where('last_activity_date >= ?', days.days.ago).count
    (active_after_days.to_f / eligible_users.count * 100).round(1)
  end
  
  def calculate_avg_progression(users)
    return 0 if users.count == 0
    users_array = users.to_a
    total_progression = users_array.sum(&:progression)
    (total_progression.to_f / users_array.count).round(1)
  end
  
  def prepare_chart_data(users)
    # Daily registration trend (group by date manually)
    # Need to reselect without ordering to avoid MySQL GROUP BY issues
    registration_trend = User.where(id: users.select(:id))
                            .group("DATE(created_at)")
                            .count
                            .transform_keys { |k| k.to_date }
    
    # Progression funnel (progression is a method, need to calculate in memory)
    users_array = users.to_a
    progression_funnel = {
      'Registered' => users.count,
      'Activated' => users.where.not(confirmed_at: nil).count,
      'Added Verses' => users.joins(:memverses).distinct.count,
      'Started Learning' => users_array.count { |u| u.progression >= 5 },
      'Engaged User' => users_array.count { |u| u.progression >= 7 },
      'First Memorization' => users_array.count { |u| u.progression >= 9 }
    }
    
    # Progression distribution (progression is a method, not a column)
    progression_distribution = users.to_a.group_by(&:progression).transform_values(&:count)
    
    # Activity heatmap data
    activity_heatmap = prepare_activity_heatmap(users)
    
    {
      registration_trend: registration_trend,
      progression_funnel: progression_funnel,
      progression_distribution: progression_distribution,
      activity_heatmap: activity_heatmap
    }
  end
  
  def prepare_activity_heatmap(users)
    heatmap_data = []
    
    (0..14).each do |days_since|
      # Get users created on this day (reselect to avoid ordering issues)
      day_users = User.where(id: users.select(:id))
                      .where('DATE(created_at) = ?', days_since.days.ago.to_date)
                      .to_a
      
      (0..9).each do |progression_level|
        # Count users at this progression level
        count = day_users.count { |u| u.progression == progression_level }
        
        heatmap_data << {
          day: days_since,
          level: progression_level,
          count: count
        } if count > 0
      end
    end
    
    heatmap_data
  end
  
  def generate_csv(users)
    CSV.generate(headers: true) do |csv|
      csv << [
        'ID', 'Name/Login', 'Email', 'Registration Date', 'Days Since Registration',
        'Progression Level', 'Email Confirmed', 'Verses Added', 'Memorized',
        'Learning', 'Last Activity', 'Translation', 'Country', 'State', 
        'Church', 'Group', 'Referrer'
      ]
      
      users.each do |user|
        csv << [
          user.id,
          user.name_or_login,
          user.email,
          user.created_at.strftime('%Y-%m-%d %H:%M'),
          (Date.current - user.created_at.to_date).to_i,
          user.progression,
          user.confirmed_at.present? ? 'Yes' : 'No',
          user.memverses.count,
          user.memorized,
          user.learning,
          user.last_activity_date&.strftime('%Y-%m-%d'),
          user.translation,
          user.country&.name,
          user.american_state&.name,
          user.church&.name,
          user.group&.name,
          user.referred_by
        ]
      end
    end
  end
end