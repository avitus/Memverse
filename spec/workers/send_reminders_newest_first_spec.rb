require 'spec_helper'

RSpec.describe SendReminders, type: :worker do
  let(:worker) { described_class.new }
  
  describe 'processes users from newest to oldest' do
    let!(:old_user) do
      FactoryBot.create(:user,
                       confirmed_at: 1.week.ago,
                       created_at: 1.month.ago,
                       email: 'old@example.com',
                       reminder_freq: 'Weekly',
                       last_reminder: 2.weeks.ago)
    end
    
    let!(:new_user) do
      FactoryBot.create(:user,
                       confirmed_at: 1.week.ago,
                       created_at: 1.day.ago,
                       email: 'new@example.com',
                       reminder_freq: 'Weekly',
                       last_reminder: 2.weeks.ago)
    end
    
    let!(:email_double) { double('email', deliver: true) }
    
    before do
      # Mock Rails logger
      allow(Rails.logger).to receive(:info)
      
      # Mock UserMailer
      allow(UserMailer).to receive(:progression_email_2).and_return(email_double)
      
      # Mock needs_reminder? to return true
      allow(old_user).to receive(:needs_reminder?).and_return(true)
      allow(new_user).to receive(:needs_reminder?).and_return(true)
      
      # Mock progression level
      allow(old_user).to receive(:progression).and_return(2)
      allow(new_user).to receive(:progression).and_return(2)
      
      # Mock update methods
      allow(old_user).to receive(:update_reminder_freq)
      allow(new_user).to receive(:update_reminder_freq)
      allow(old_user).to receive(:update_attribute)
      allow(new_user).to receive(:update_attribute)
    end
    
    it 'processes newest users first when sending reminders' do
      # Set throttle to 1 so only one email is sent
      worker.instance_variable_set(:@throttle, 1)
      
      # Expect the new user to get the email, not the old user
      expect(UserMailer).to receive(:progression_email_2).with(new_user).and_return(email_double)
      expect(UserMailer).not_to receive(:progression_email_2).with(old_user)
      
      # Expect only the new user's last_reminder to be updated
      expect(new_user).to receive(:update_attribute).with(:last_reminder, Date.today)
      expect(old_user).not_to receive(:update_attribute)
      
      worker.perform
    end
    
    it 'uses order(created_at: :desc) to sort users' do
      expect(User).to receive(:order).with(created_at: :desc).and_call_original
      worker.perform
    end
    
    it 'uses in_batches to process users efficiently' do
      ordered_relation = User.order(created_at: :desc)
      expect(User).to receive(:order).with(created_at: :desc).and_return(ordered_relation)
      expect(ordered_relation).to receive(:in_batches).with(of: 1000).and_call_original
      worker.perform
    end
    
    it 'processes users in the correct order within each batch' do
      # Create more users to test ordering
      middle_user = FactoryBot.create(:user,
                                     confirmed_at: 1.week.ago,
                                     created_at: 1.week.ago,
                                     email: 'middle@example.com',
                                     reminder_freq: 'Weekly',
                                     last_reminder: 2.weeks.ago)
      
      allow(middle_user).to receive(:needs_reminder?).and_return(true)
      allow(middle_user).to receive(:progression).and_return(2)
      allow(middle_user).to receive(:update_reminder_freq)
      allow(middle_user).to receive(:update_attribute)
      
      processed_users = []
      
      # Capture which users are processed in which order
      allow(UserMailer).to receive(:progression_email_2) do |user|
        processed_users << user.email
        email_double
      end
      
      worker.perform
      
      # Verify that users were processed from newest to oldest
      expect(processed_users).to eq(['new@example.com', 'middle@example.com', 'old@example.com'])
    end
  end
end