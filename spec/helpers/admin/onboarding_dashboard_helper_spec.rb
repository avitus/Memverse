require 'rails_helper'

RSpec.describe Admin::OnboardingDashboardHelper, type: :helper do
  describe '#progression_badge' do
    it 'returns correct badge for level 0-1' do
      result = helper.progression_badge(0)
      expect(result).to include('Not Started')
      expect(result).to include('bg-red-100')
    end
    
    it 'returns correct badge for level 2' do
      result = helper.progression_badge(2)
      expect(result).to include('Activated')
      expect(result).to include('bg-yellow-100')
    end
    
    it 'returns correct badge for level 3-4' do
      result = helper.progression_badge(3)
      expect(result).to include('Getting Started')
      expect(result).to include('bg-blue-100')
    end
    
    it 'returns correct badge for level 5-6' do
      result = helper.progression_badge(5)
      expect(result).to include('Engaged')
      expect(result).to include('bg-orange-100')
    end
    
    it 'returns correct badge for level 7-8' do
      result = helper.progression_badge(7)
      expect(result).to include('Active User')
      expect(result).to include('bg-green-100')
    end
    
    it 'returns correct badge for level 9' do
      result = helper.progression_badge(9)
      expect(result).to include('Successful')
      expect(result).to include('bg-purple-100')
    end
  end
  
  describe '#activity_status_indicator' do
    let(:user) { FactoryBot.build(:user) }
    
    it 'returns gray indicator for never active user' do
      user.last_activity_date = nil
      result = helper.activity_status_indicator(user)
      expect(result).to include('text-gray-400')
      expect(result).to include('Never active')
    end
    
    it 'returns green indicator for active user' do
      user.last_activity_date = 1.day.ago
      result = helper.activity_status_indicator(user)
      expect(result).to include('text-green-500')
      expect(result).to include('Active')
    end
    
    it 'returns yellow indicator for recently active user' do
      user.last_activity_date = 15.days.ago
      result = helper.activity_status_indicator(user)
      expect(result).to include('text-yellow-500')
      expect(result).to include('Recently active')
    end
    
    it 'returns red indicator for inactive user' do
      user.last_activity_date = 35.days.ago
      result = helper.activity_status_indicator(user)
      expect(result).to include('text-red-500')
      expect(result).to include('Inactive')
    end
  end
  
  describe '#days_since_registration' do
    it 'calculates correct days since registration' do
      user = FactoryBot.build(:user, created_at: 5.days.ago)
      expect(helper.days_since_registration(user)).to eq(5)
    end
  end
  
  describe '#email_confirmation_badge' do
    let(:user) { FactoryBot.build(:user) }
    
    it 'returns checkmark for confirmed user' do
      user.confirmed_at = 1.day.ago
      result = helper.email_confirmation_badge(user)
      expect(result).to include('✓')
      expect(result).to include('text-green-600')
    end
    
    it 'returns X for unconfirmed user' do
      user.confirmed_at = nil
      result = helper.email_confirmation_badge(user)
      expect(result).to include('✗')
      expect(result).to include('text-red-600')
    end
  end
  
  describe '#translation_indicator' do
    let(:user) { FactoryBot.build(:user) }
    
    it 'returns translation name when set' do
      user.translation = 'NIV'
      result = helper.translation_indicator(user)
      expect(result).to include('NIV')
      expect(result).not_to include('Not set')
    end
    
    it 'returns "Not set" when translation is blank' do
      user.translation = nil
      result = helper.translation_indicator(user)
      expect(result).to include('Not set')
      expect(result).to include('italic')
    end
  end
  
  describe '#metric_change_indicator' do
    it 'shows positive change with up arrow' do
      result = helper.metric_change_indicator(110, 100)
      expect(result).to include('↑')
      expect(result).to include('10.0%')
      expect(result).to include('text-green-600')
    end
    
    it 'shows negative change with down arrow' do
      result = helper.metric_change_indicator(90, 100)
      expect(result).to include('↓')
      expect(result).to include('10.0%')
      expect(result).to include('text-red-600')
    end
    
    it 'shows no change with right arrow' do
      result = helper.metric_change_indicator(100, 100)
      expect(result).to include('→')
      expect(result).to include('0%')
      expect(result).to include('text-gray-600')
    end
    
    it 'returns empty string when previous is 0' do
      result = helper.metric_change_indicator(100, 0)
      expect(result).to eq('')
    end
  end
  
  describe '#onboarding_risk_score' do
    let(:user) { FactoryBot.build(:user, created_at: 5.days.ago) }
    
    it 'returns low risk for engaged user' do
      user.confirmed_at = 4.days.ago
      allow(user).to receive(:progression).and_return(5)
      user.last_activity_date = 1.day.ago
      user.translation = 'NIV'
      allow(user).to receive_message_chain(:memverses, :count).and_return(5)
      
      result = helper.onboarding_risk_score(user)
      expect(result).to include('Low Risk')
      expect(result).to include('text-green-600')
    end
    
    it 'returns high risk for unengaged user' do
      user.confirmed_at = nil
      allow(user).to receive(:progression).and_return(1)
      user.last_activity_date = nil
      user.translation = nil
      allow(user).to receive_message_chain(:memverses, :count).and_return(0)
      
      result = helper.onboarding_risk_score(user)
      expect(result).to include('High Risk')
      expect(result).to include('text-red-600')
    end
  end
  
  describe '#format_date_short' do
    it 'returns "Today" for current date' do
      expect(helper.format_date_short(Date.current)).to eq('Today')
    end
    
    it 'returns "Yesterday" for yesterday' do
      expect(helper.format_date_short(Date.yesterday)).to eq('Yesterday')
    end
    
    it 'returns days ago for recent dates' do
      expect(helper.format_date_short(3.days.ago)).to eq('3 days ago')
    end
    
    it 'returns formatted date for older dates' do
      date = 30.days.ago
      expect(helper.format_date_short(date)).to eq(date.strftime('%m/%d'))
    end
    
    it 'returns dash for nil date' do
      expect(helper.format_date_short(nil)).to eq('-')
    end
  end
  
  describe '#user_location_info' do
    let(:user) { FactoryBot.build(:user) }
    let(:country) { FactoryBot.build(:country, name: 'United States') }
    let(:state) { FactoryBot.build(:american_state, name: 'California') }
    
    it 'returns country and state when both present' do
      user.country = country
      user.american_state = state
      expect(helper.user_location_info(user)).to eq('United States, California')
    end
    
    it 'returns only country when state not present' do
      user.country = country
      expect(helper.user_location_info(user)).to eq('United States')
    end
    
    it 'returns "Not specified" when no location' do
      result = helper.user_location_info(user)
      expect(result).to include('Not specified')
      expect(result).to include('italic')
    end
  end
  
  describe '#user_community_info' do
    let(:user) { FactoryBot.build(:user) }
    let(:church) { FactoryBot.build(:church, name: 'Test Church') }
    let(:group) { FactoryBot.build(:group, name: 'Test Group') }
    
    it 'returns church and group when both present' do
      user.church = church
      user.group = group
      expect(helper.user_community_info(user)).to eq('Church: Test Church | Group: Test Group')
    end
    
    it 'returns only church when group not present' do
      user.church = church
      expect(helper.user_community_info(user)).to eq('Church: Test Church')
    end
    
    it 'returns "No community" when neither present' do
      result = helper.user_community_info(user)
      expect(result).to include('No community')
      expect(result).to include('italic')
    end
  end
  
  describe '#metric_card' do
    it 'creates a metric card with all parameters' do
      result = helper.metric_card('Total Users', '100', 'Last 14 days', '+10%', 'bg-primary')
      expect(result).to include('Total Users')
      expect(result).to include('100')
      expect(result).to include('Last 14 days')
      expect(result).to include('+10%')
      expect(result).to include('bg-primary')
    end
    
    it 'creates a metric card without optional parameters' do
      result = helper.metric_card('Total Users', '100')
      expect(result).to include('Total Users')
      expect(result).to include('100')
      expect(result).to include('bg-white')
    end
  end
end