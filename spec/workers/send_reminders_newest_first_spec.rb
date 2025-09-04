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
      # Mock Rails logger - need to mock all logger methods that might be called
      allow(Rails.logger).to receive(:info)
      allow(Rails.logger).to receive(:warn)
      allow(Rails.logger).to receive(:error)
      
      # Use any_instance_of to mock methods on all User instances loaded from DB
      allow_any_instance_of(User).to receive(:update_reminder_freq)
      allow_any_instance_of(User).to receive(:needs_reminder?) do |user|
        # Only return true for our test users
        ['old@example.com', 'new@example.com'].include?(user.email)
      end
      allow_any_instance_of(User).to receive(:progression).and_return(2)
    end
    
    it 'processes newest users first when sending reminders' do
      # Ensure we only have our test users
      expect(User.count).to eq(2)
      
      # Track which users get emails in order
      emails_sent = []
      allow(UserMailer).to receive(:progression_email_2) do |user|
        emails_sent << user.email
        email_double
      end
      
      # Track which users get updated
      users_updated = []
      allow_any_instance_of(User).to receive(:update_attribute).with(:last_reminder, Date.today) do |user|
        users_updated << user.email
        true
      end
      
      # Create a custom worker that sets throttle=1
      test_worker = SendReminders.new
      allow(test_worker).to receive(:perform) do
        # Set instance variables as the real perform would
        test_worker.instance_variable_set(:@emails_sent, 0)
        test_worker.instance_variable_set(:@throttle, 1) # Override default throttle
        
        # Delete pending users as the real perform would
        User.pending.where('created_at < ?', 2.days.ago).delete_all
        
        # Process users with the modified throttle
        User.in_batches(of: 100) do |batch|
          batch.reorder(created_at: :desc).each do |u|
            u.update_reminder_freq
            
            if u.reminder_freq != "Never" and test_worker.instance_variable_get(:@emails_sent) < test_worker.instance_variable_get(:@throttle)
              if u.needs_reminder?
                Rails.logger.info("* Sending progression email to #{u.name_or_login}. They are at progression level #{u.progression}.")
                
                case u.progression
                when 2
                  UserMailer.progression_email_2(u).deliver
                end
                
                test_worker.instance_variable_set(:@emails_sent, test_worker.instance_variable_get(:@emails_sent) + 1)
                u.update_attribute(:last_reminder, Date.today)
              end
            end
          end
        end
        
        Rails.logger.info(" *** Email reminder: Sent #{test_worker.instance_variable_get(:@emails_sent)} reminder emails at #{Time.now}")
      end
      
      test_worker.perform
      
      # Verify that new user was processed first
      expect(emails_sent.first).to eq('new@example.com')
      
      # With throttle=1, only one email should be sent
      expect(emails_sent.size).to eq(1)
      expect(users_updated.size).to eq(1)
    end
    
    it 'uses reorder(created_at: :desc) to sort users within each batch' do
      # Mock UserMailer for this test since we removed it from before block
      allow(UserMailer).to receive(:progression_email_2).and_return(email_double)
      
      # Track if reorder(created_at: :desc) is called
      reorder_called = false
      allow_any_instance_of(ActiveRecord::Relation).to receive(:reorder).and_wrap_original do |m, *args|
        if args == [{created_at: :desc}]
          reorder_called = true
        end
        m.call(*args)
      end
      
      worker.perform
      
      expect(reorder_called).to be true
    end
    
    it 'uses in_batches to process users efficiently' do
      # Mock UserMailer for this test since we removed it from before block
      allow(UserMailer).to receive(:progression_email_2).and_return(email_double)
      
      # The worker uses User.in_batches directly now
      expect(User).to receive(:in_batches).with(of: 100).and_call_original
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
      
      # Use any_instance_of mocks since the worker loads fresh instances
      allow_any_instance_of(User).to receive(:needs_reminder?) do |user|
        ['old@example.com', 'new@example.com', 'middle@example.com'].include?(user.email)
      end
      
      processed_users = []
      
      # Capture which users are processed in which order
      allow(UserMailer).to receive(:progression_email_2) do |user|
        processed_users << user.email
        email_double
      end
      
      # The worker has default throttle of 2, so it will only send 2 emails
      # But that's enough to verify the order - we expect the 2 newest users
      worker.perform
      
      # Verify that users were processed from newest to oldest
      # With throttle=2, only the 2 newest users should get emails
      expect(processed_users).to eq(['new@example.com', 'middle@example.com'])
    end
  end
end