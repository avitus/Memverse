module Admin::OnboardingDashboardHelper
  
  def progression_badge(level)
    text, css_class = case level
                      when 0..1
                        ['Not Started', 'bg-red-100 text-red-800']
                      when 2
                        ['Activated', 'bg-yellow-100 text-yellow-800']
                      when 3..4
                        ['Getting Started', 'bg-blue-100 text-blue-800']
                      when 5..6
                        ['Engaged', 'bg-orange-100 text-orange-800']
                      when 7..8
                        ['Active User', 'bg-green-100 text-green-800']
                      when 9
                        ['Successful', 'bg-purple-100 text-purple-800']
                      else
                        ['Unknown', 'bg-gray-100 text-gray-800']
                      end
    
    content_tag :span, "#{level} - #{text}", 
                class: "px-2 py-1 text-xs font-medium rounded-full #{css_class}"
  end
  
  def activity_status_indicator(user)
    if user.last_activity_date.nil?
      content_tag :span, '●', class: 'text-gray-400', title: 'Never active'
    elsif user.last_activity_date >= 7.days.ago
      content_tag :span, '●', class: 'text-green-500', title: 'Active'
    elsif user.last_activity_date >= 30.days.ago
      content_tag :span, '●', class: 'text-yellow-500', title: 'Recently active'
    else
      content_tag :span, '●', class: 'text-red-500', title: 'Inactive'
    end
  end
  
  def days_since_registration(user)
    (Date.current - user.created_at.to_date).to_i
  end
  
  def email_confirmation_badge(user)
    if user.confirmed_at.present?
      content_tag :span, '✓', class: 'text-green-600 font-bold', title: "Confirmed: #{user.confirmed_at.strftime('%Y-%m-%d')}"
    else
      content_tag :span, '✗', class: 'text-red-600 font-bold', title: 'Not confirmed'
    end
  end
  
  def translation_indicator(user)
    if user.translation.present?
      content_tag :span, user.translation, class: 'text-sm text-gray-700'
    else
      content_tag :span, 'Not set', class: 'text-sm text-gray-400 italic'
    end
  end
  
  def metric_change_indicator(current, previous)
    return '' if previous == 0
    
    change = ((current - previous).to_f / previous * 100).round(1)
    
    if change > 0
      content_tag :span, "↑ #{change}%", class: 'text-green-600 text-sm font-medium'
    elsif change < 0
      content_tag :span, "↓ #{change.abs}%", class: 'text-red-600 text-sm font-medium'
    else
      content_tag :span, '→ 0%', class: 'text-gray-600 text-sm font-medium'
    end
  end
  
  def onboarding_risk_score(user)
    score = 0
    days_since = days_since_registration(user)
    
    # Risk factors
    score += 3 if user.confirmed_at.nil? && days_since > 2
    score += 3 if user.memverses.count == 0 && days_since > 3
    score += 2 if user.translation.blank? && days_since > 1
    score += 2 if user.last_activity_date.nil? || user.last_activity_date < 3.days.ago
    score += 1 if user.progression < 3 && days_since > 7
    
    case score
    when 0..2
      content_tag :span, 'Low Risk', class: 'text-green-600 text-xs font-medium'
    when 3..5
      content_tag :span, 'Medium Risk', class: 'text-yellow-600 text-xs font-medium'
    else
      content_tag :span, 'High Risk', class: 'text-red-600 text-xs font-medium'
    end
  end
  
  def format_date_short(date)
    return '-' if date.nil?
    
    if date.to_date == Date.current
      'Today'
    elsif date.to_date == Date.yesterday
      'Yesterday'
    elsif date > 7.days.ago
      "#{(Date.current - date.to_date).to_i} days ago"
    else
      date.strftime('%m/%d')
    end
  end
  
  def user_location_info(user)
    parts = []
    parts << user.country.name if user.country
    parts << user.american_state.name if user.american_state
    
    if parts.any?
      parts.join(', ')
    else
      content_tag :span, 'Not specified', class: 'text-gray-400 italic'
    end
  end
  
  def user_community_info(user)
    parts = []
    parts << "Church: #{user.church.name}" if user.church
    parts << "Group: #{user.group.name}" if user.group
    
    if parts.any?
      parts.join(' | ')
    else
      content_tag :span, 'No community', class: 'text-gray-400 italic'
    end
  end
  
  def metric_card(title, value, subtitle = nil, change = nil, css_class = 'bg-white')
    content_tag :div, class: "#{css_class} rounded-lg shadow p-6" do
      content_tag(:div, class: 'flex items-center justify-between') do
        content_tag(:div) do
          content_tag(:p, title, class: 'text-sm font-medium text-gray-600') +
          content_tag(:p, value, class: 'text-2xl font-semibold text-gray-900 mt-1') +
          (subtitle ? content_tag(:p, subtitle, class: 'text-xs text-gray-500 mt-1') : '') +
          (change ? content_tag(:div, change, class: 'mt-2') : '')
        end
      end
    end
  end
  
  def progression_level_options
    [
      ['All Levels', ''],
      ['0-1: Not Started', 'not_started'],
      ['2: Activated', 'activated'],
      ['3-4: Getting Started', 'getting_started'],
      ['5-6: Engaged', 'engaged'],
      ['7-8: Active', 'active'],
      ['9: Successful', 'successful']
    ]
  end
  
  def activity_status_options
    [
      ['All Activity', ''],
      ['Active (< 7 days)', 'active'],
      ['Recently Active (7-30 days)', 'recently_active'],
      ['Inactive (> 30 days)', 'inactive']
    ]
  end
  
  def email_status_options
    [
      ['All Email Status', ''],
      ['Confirmed', 'confirmed'],
      ['Unconfirmed', 'unconfirmed']
    ]
  end
  
  def translation_status_options
    [
      ['All Translation Status', ''],
      ['Translation Set', 'set'],
      ['Translation Not Set', 'not_set']
    ]
  end
  
  def date_range_options
    [
      ['Last 7 days', 7],
      ['Last 14 days', 14],
      ['Last 30 days', 30],
      ['Last 60 days', 60],
      ['Last 90 days', 90]
    ]
  end
  
  # Calculate metric change percentage
  def metric_change_percentage(current, previous)
    return 0 if previous == 0
    ((current - previous).to_f / previous * 100).round(1)
  end
  
  # Determine metric change class for styling
  def metric_change_class(current, previous)
    return 'neutral' if current == previous
    current > previous ? 'positive' : 'negative'
  end
  
  # Activity status class for status indicator
  def activity_status_class(user)
    if user.last_activity_date.nil?
      'inactive'
    elsif user.last_activity_date >= 7.days.ago
      'active'
    elsif user.last_activity_date >= 30.days.ago
      'recently-active'
    else
      'inactive'
    end
  end
  
  # Onboarding risk class for styling
  def onboarding_risk_class(user)
    score = 0
    days_since = days_since_registration(user)
    
    # Risk factors
    score += 3 if user.confirmed_at.nil? && days_since > 2
    score += 3 if user.memverses.count == 0 && days_since > 3
    score += 2 if user.translation.blank? && days_since > 1
    score += 2 if user.last_activity_date.nil? || user.last_activity_date < 3.days.ago
    score += 1 if user.progression < 3 && days_since > 7
    
    case score
    when 0..2
      'low'
    when 3..5
      'medium'
    else
      'high'
    end
  end
  
  # Onboarding risk level
  def onboarding_risk_level(user)
    css_class = onboarding_risk_class(user)
    
    case css_class
    when 'low'
      'Low'
    when 'medium'
      'Med'
    else
      'High'
    end
  end
end