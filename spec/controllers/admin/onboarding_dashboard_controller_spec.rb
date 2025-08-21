require 'rails_helper'

RSpec.describe Admin::OnboardingDashboardController, type: :controller do
  let(:admin_user) { FactoryBot.create(:user, admin: true, created_at: 20.days.ago) }
  let(:regular_user) { FactoryBot.create(:user, admin: false, created_at: 20.days.ago) }
  
  describe 'authentication' do
    context 'when user is not logged in' do
      it 'redirects to root path' do
        get :index
        expect(response).to redirect_to(root_path)
        expect(flash[:error]).to eq('You must be an admin to access this page')
      end
    end
    
    context 'when regular user is logged in' do
      before { sign_in regular_user }
      
      it 'redirects to root path' do
        get :index
        expect(response).to redirect_to(root_path)
        expect(flash[:error]).to eq('You must be an admin to access this page')
      end
    end
    
    context 'when admin user is logged in' do
      before { sign_in admin_user }
      
      it 'allows access to index' do
        get :index
        expect(response).to be_successful
      end
      
      it 'allows access to show' do
        user = FactoryBot.create(:user)
        get :show, params: { id: user.id }
        expect(response).to be_successful
      end
    end
  end
  
  describe 'GET #index' do
    before { sign_in admin_user }
    
    context 'with no date range parameter' do
      it 'defaults to past 14 days' do
        get :index
        expect(assigns(:date_range).first).to be_within(1.minute).of(14.days.ago)
        expect(assigns(:date_range).last).to be_within(1.minute).of(Time.current)
      end
    end
    
    context 'with date range parameter' do
      it 'uses specified date range' do
        get :index, params: { date_range: 30 }
        expect(assigns(:date_range).first).to be_within(1.minute).of(30.days.ago)
      end
    end
    
    context 'with new users' do
      let!(:new_user_1) { FactoryBot.create(:user, created_at: 5.days.ago) }
      let!(:new_user_2) { FactoryBot.create(:user, created_at: 10.days.ago) }
      let!(:old_user) { FactoryBot.create(:user, created_at: 20.days.ago) }
      
      it 'includes only users within date range' do
        get :index
        users = assigns(:new_users)
        expect(users).to include(new_user_1, new_user_2)
        expect(users).not_to include(old_user)
      end
      
      it 'orders users by created_at desc' do
        get :index
        users = assigns(:new_users).to_a
        expect(users.first.created_at).to be > users.last.created_at
      end
    end
    
    context 'with filters' do
      let!(:activated_user) { FactoryBot.create(:user, created_at: 1.day.ago, confirmed_at: 1.day.ago) }
      let!(:unconfirmed_user) { FactoryBot.create(:user, created_at: 1.day.ago, confirmed_at: nil) }
      let!(:engaged_user) { FactoryBot.create(:user, created_at: 1.day.ago, confirmed_at: 1.day.ago) }
      
      it 'filters by progression level' do
        # Add verses to engaged user to increase progression
        5.times { engaged_user.memverses.create!(verse: FactoryBot.create(:verse), status: 'Learning') }
        
        get :index, params: { progression_level: 'activated' }
        users = assigns(:new_users)
        expect(users).to include(activated_user)
        expect(users).not_to include(unconfirmed_user, engaged_user)
      end
      
      it 'filters by email status' do
        get :index, params: { email_status: 'unconfirmed' }
        users = assigns(:new_users)
        expect(users).to include(unconfirmed_user)
        expect(users).not_to include(activated_user)
      end
      
      it 'filters by activity status' do
        active_user = FactoryBot.create(:user, created_at: 1.day.ago, last_activity_date: 1.day.ago)
        inactive_user = FactoryBot.create(:user, created_at: 1.day.ago, last_activity_date: 35.days.ago)
        
        get :index, params: { activity_status: 'active' }
        users = assigns(:new_users)
        expect(users).to include(active_user)
        expect(users).not_to include(inactive_user)
      end
      
      it 'filters by translation status' do
        with_translation = FactoryBot.create(:user, created_at: 1.day.ago, translation: 'NIV')
        without_translation = FactoryBot.create(:user, created_at: 1.day.ago, translation: nil)
        
        get :index, params: { translation_status: 'set' }
        users = assigns(:new_users)
        expect(users).to include(with_translation)
        expect(users).not_to include(without_translation)
      end
    end
    
    context 'metrics calculation' do
      let!(:users) do
        [
          FactoryBot.create(:user, created_at: 1.day.ago, confirmed_at: 1.day.ago, memorized: 5),
          FactoryBot.create(:user, created_at: 2.days.ago, confirmed_at: nil, memorized: 0),
          FactoryBot.create(:user, created_at: 3.days.ago, confirmed_at: 2.days.ago, memorized: 2)
        ]
      end
      
      before do
        users.first.memverses.create!(verse: FactoryBot.create(:verse), status: 'Memorized')
        users.last.memverses.create!(verse: FactoryBot.create(:verse), status: 'Learning')
      end
      
      it 'calculates correct metrics' do
        # Force reload users and update memorized counts
        users.first.reload.update_column(:memorized, 5)
        users.last.reload.update_column(:memorized, 2)
        
        get :index
        metrics = assigns(:metrics)
        
        expect(metrics[:total_users]).to eq(3)
        expect(metrics[:activated]).to eq(2)
        expect(metrics[:activation_rate]).to be_within(0.1).of(66.7)
        expect(metrics[:added_verses]).to eq(2)
        expect(metrics[:engagement_rate]).to be_within(0.1).of(66.7)
        expect(metrics[:memorized_any]).to eq(2)
      end
    end
    
    context 'CSV export' do
      let!(:user) { FactoryBot.create(:user, created_at: 1.day.ago, name: 'Test User') }
      
      it 'exports users as CSV' do
        get :index, format: :csv
        expect(response.content_type).to include('text/csv')
        expect(response.body).to include('Test User')
      end
    end
  end
  
  describe 'GET #show' do
    before { sign_in admin_user }
    let(:user) { FactoryBot.create(:user) }
    
    it 'loads the requested user' do
      get :show, params: { id: user.id }
      expect(assigns(:user)).to eq(user)
    end
    
    it 'loads recent memverses' do
      memverse = FactoryBot.create(:memverse, user: user)
      get :show, params: { id: user.id }
      expect(assigns(:memverses)).to include(memverse)
    end
    
    it 'loads recent progress reports' do
      report = FactoryBot.create(:progress_report, user: user)
      get :show, params: { id: user.id }
      expect(assigns(:progress_reports).to_a).to include(report)
    end
  end
  
  describe 'POST #email_unengaged' do
    before { sign_in admin_user }
    
    let!(:unengaged_user) { FactoryBot.create(:user, created_at: 5.days.ago, confirmed_at: 4.days.ago) }
    let!(:engaged_user) { FactoryBot.create(:user, created_at: 5.days.ago, confirmed_at: 4.days.ago) }
    let!(:unconfirmed_user) { FactoryBot.create(:user, created_at: 5.days.ago, confirmed_at: nil) }
    
    before do
      # Clear any previous deliveries
      ActionMailer::Base.deliveries.clear
      
      # Mock progression for users - need to stub on User class since controller loads fresh instances
      allow_any_instance_of(User).to receive(:progression) do |user|
        case user.id
        when unengaged_user.id
          1  # Unengaged
        when engaged_user.id
          5  # Engaged
        else
          0  # Default
        end
      end
    end
    
    it 'sends emails to unengaged confirmed users' do
      # Use deliver_now instead of deliver_later for testing
      expect_any_instance_of(ActionMailer::MessageDelivery).to receive(:deliver_later).and_wrap_original do |method, *args|
        method.receiver.deliver_now
      end
      
      expect {
        post :email_unengaged
      }.to change { ActionMailer::Base.deliveries.count }.by(1)
      
      # Verify it's sent to the correct user
      expect(ActionMailer::Base.deliveries.last.to).to include(unengaged_user.email)
    end
    
    it 'does not send emails to engaged users' do
      # Use deliver_now instead of deliver_later for testing
      expect_any_instance_of(ActionMailer::MessageDelivery).to receive(:deliver_later).and_wrap_original do |method, *args|
        method.receiver.deliver_now
      end
      
      post :email_unengaged
      
      email_recipients = ActionMailer::Base.deliveries.map(&:to).flatten
      expect(email_recipients).to include(unengaged_user.email)
      expect(email_recipients).not_to include(engaged_user.email)
      expect(email_recipients).not_to include(unconfirmed_user.email)
    end
    
    it 'redirects with success message' do
      post :email_unengaged
      expect(response).to redirect_to(admin_onboarding_dashboard_index_path)
      expect(flash[:success]).to match(/Reminder emails sent to \d+ unengaged users/)
    end
  end
  
  describe 'private methods' do
    before { sign_in admin_user }
    
    describe '#calculate_retention_rate' do
      it 'calculates correct retention rate' do
        old_active = FactoryBot.create(:user, created_at: 10.days.ago, last_activity_date: 1.day.ago)
        old_inactive = FactoryBot.create(:user, created_at: 10.days.ago, last_activity_date: 15.days.ago)
        
        get :index
        # The retention rate should be 50% (1 of 2 users active after 7 days)
        expect(assigns(:metrics)[:retention_rate_7d]).to be_within(0.1).of(50.0)
      end
    end
  end
end