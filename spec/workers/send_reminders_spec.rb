require 'spec_helper'

RSpec.describe SendReminders, type: :worker do
  let(:worker) { described_class.new }
  let(:perform_args) { [] }

  # Include shared examples for Sidekiq workers
  include_examples 'a Sidekiq worker'
  include_examples 'a non-retryable worker'
  include_examples 'a worker with specific queue', :high
  include_examples 'performs logging'

  describe '#perform' do
    let!(:email_double) { double('email', deliver: true) }
    
    before do
      # Mock Rails logger to capture logging
      allow(Rails.logger).to receive(:info)
      
      # Mock UserMailer methods to avoid actual email sending
      (2..9).each do |level|
        allow(UserMailer).to receive("progression_email_#{level}").and_return(email_double)
      end
    end

    describe 'inactive user deletion' do
      let!(:old_pending_user) do
        FactoryBot.create(:user, 
                         confirmed_at: nil, 
                         created_at: 3.days.ago,
                         email: 'old_pending@example.com')
      end
      
      let!(:recent_pending_user) do
        FactoryBot.create(:user, 
                         confirmed_at: nil, 
                         created_at: 1.day.ago,
                         email: 'recent_pending@example.com')
      end
      
      let!(:confirmed_user) do
        FactoryBot.create(:user, 
                         confirmed_at: 1.day.ago, 
                         created_at: 3.days.ago,
                         email: 'confirmed@example.com')
      end

      it 'deletes users who have been pending for more than 2 days' do
        expect { worker.perform }.to change { User.count }.by(-1)
        expect(User.exists?(old_pending_user.id)).to be_falsey
      end

      it 'does not delete recently created pending users' do
        worker.perform
        expect(User.exists?(recent_pending_user.id)).to be_truthy
      end

      it 'does not delete confirmed users regardless of age' do
        worker.perform
        expect(User.exists?(confirmed_user.id)).to be_truthy
      end
    end

    describe 'email throttling' do
      let!(:users_needing_reminders) do
        (1..60).map do |i|
          user = FactoryBot.create(:user,
                                  confirmed_at: 1.week.ago,
                                  email: "user#{i}@example.com",
                                  reminder_freq: 'Weekly',
                                  last_reminder: 2.weeks.ago)
          
          # Mock the user to need a reminder
          allow(user).to receive(:needs_reminder?).and_return(true)
          allow(user).to receive(:progression).and_return(2)
          allow(user).to receive(:update_reminder_freq)
          allow(user).to receive(:update_attribute)
          user
        end
      end

      before do
        # Mock User.find_each to iterate over our test users
        allow(User).to receive(:find_each) do |&block|
          users_needing_reminders.each(&block)
        end
      end

      it 'limits emails to 50 per run' do
        expect(UserMailer).to receive(:progression_email_2).exactly(50).times
        worker.perform
      end

      it 'logs the number of emails sent' do
        expect(Rails.logger).to receive(:info).with(/Sent 50 reminder emails/)
        worker.perform
      end
    end

    describe 'progression level email routing' do
      let(:base_user_attrs) do
        {
          confirmed_at: 1.week.ago,
          email: 'test@example.com',
          reminder_freq: 'Weekly',
          last_reminder: 2.weeks.ago
        }
      end

      before do
        # Mock update methods
        allow_any_instance_of(User).to receive(:update_reminder_freq)
        allow_any_instance_of(User).to receive(:update_attribute)
        allow_any_instance_of(User).to receive(:needs_reminder?).and_return(true)
        allow_any_instance_of(User).to receive(:name_or_login).and_return('Test User')
      end

      shared_examples 'sends correct progression email' do |level|
        it "sends progression_email_#{level} for progression level #{level}" do
          user = FactoryBot.create(:user, base_user_attrs)
          allow(user).to receive(:progression).and_return(level)
          allow(User).to receive(:find_each) do |&block|
            [user].each(&block)
          end

          expect(UserMailer).to receive("progression_email_#{level}").with(user).and_return(email_double)
          expect(email_double).to receive(:deliver)
          
          worker.perform
        end
      end

      (2..9).each do |level|
        include_examples 'sends correct progression email', level
      end

      it 'does not send email for progression level 1 (unconfirmed users)' do
        user = FactoryBot.create(:user, base_user_attrs.merge(confirmed_at: nil))
        allow(user).to receive(:progression).and_return(1)
        allow(User).to receive(:find_each) do |&block|
          [user].each(&block)
        end

        expect(UserMailer).not_to receive(:progression_email_1)
        worker.perform
      end

      it 'logs progression email details' do
        user = FactoryBot.create(:user, base_user_attrs)
        allow(user).to receive(:progression).and_return(5)
        allow(user).to receive(:name_or_login).and_return('John Doe')
        allow(User).to receive(:find_each) do |&block|
          [user].each(&block)
        end

        expect(Rails.logger).to receive(:info).with(/Sending progression email to John Doe.*progression level 5/)
        worker.perform
      end
    end

    describe 'user filtering and updates' do
      let(:user_with_blank_email) do
        user = FactoryBot.create(:user, 
                                confirmed_at: 1.week.ago,
                                reminder_freq: 'Weekly')
        # Manually set email to blank after creation to bypass validation
        user.update_column(:email, '')
        user
      end

      let(:user_never_reminders) do
        FactoryBot.create(:user,
                         confirmed_at: 1.week.ago, 
                         email: 'no_reminders@example.com',
                         reminder_freq: 'Never')
      end

      let(:user_no_reminder_needed) do
        FactoryBot.create(:user,
                         confirmed_at: 1.week.ago,
                         email: 'recent@example.com', 
                         reminder_freq: 'Weekly',
                         last_reminder: Date.today)
      end

      before do
        allow_any_instance_of(User).to receive(:update_reminder_freq)
      end

      it 'calls update_reminder_freq for all users' do
        allow(User).to receive(:find_each) do |&block|
          [user_with_blank_email].each(&block)
        end
        expect(user_with_blank_email).to receive(:update_reminder_freq)
        worker.perform
      end

      it 'skips users with blank email addresses' do
        allow(user_with_blank_email).to receive(:needs_reminder?).and_return(true)
        allow(User).to receive(:find_each) do |&block|
          [user_with_blank_email].each(&block)
        end

        expect(UserMailer).not_to receive(:progression_email_2)
        expect(Rails.logger).to receive(:info).with(/Error: Unable to email user with id: #{user_with_blank_email.id}/)
        
        worker.perform
      end

      it 'skips users who do not want reminders' do
        allow(User).to receive(:find_each) do |&block|
          [user_never_reminders].each(&block)
        end
        
        expect(UserMailer).not_to receive(:progression_email_2)
        worker.perform
      end

      it 'skips users who do not need reminders' do
        allow(user_no_reminder_needed).to receive(:needs_reminder?).and_return(false)
        allow(User).to receive(:find_each) do |&block|
          [user_no_reminder_needed].each(&block)
        end
        
        expect(UserMailer).not_to receive(:progression_email_2)
        worker.perform
      end

      it 'updates last_reminder date for users who receive emails' do
        user = FactoryBot.create(:user,
                               confirmed_at: 1.week.ago,
                               email: 'test@example.com',
                               reminder_freq: 'Weekly')
        
        allow(user).to receive(:needs_reminder?).and_return(true)
        allow(user).to receive(:progression).and_return(3)
        allow(User).to receive(:find_each) do |&block|
          [user].each(&block)
        end

        expect(user).to receive(:update_attribute).with(:last_reminder, Date.today)
        worker.perform
      end
    end

    describe 'progression level calculation integration' do
      let(:user) { FactoryBot.create(:user, confirmed_at: 1.week.ago, email: 'test@example.com') }

      before do
        allow(user).to receive(:needs_reminder?).and_return(true)
        allow(user).to receive(:update_reminder_freq)
        allow(user).to receive(:update_attribute)
        allow(User).to receive(:find_each) do |&block|
          [user].each(&block)
        end
      end

      it 'handles users with no memverses (progression level 2)' do
        expect(user.progression).to eq(2)
        expect(UserMailer).to receive(:progression_email_2).and_return(email_double)
        worker.perform
      end

      it 'handles users with memverses but no reviews (progression level 3-4)' do
        # Create memverses for the user with different verses
        3.times do |i|
          verse = FactoryBot.create(:verse, chapter: i + 1, versenum: 1)
          FactoryBot.create(:memverse, user: user, verse: verse)
        end
        
        # Reload user to get updated memverses association
        user.reload
        
        # Progression should be 3 (has added 1-5 verses)
        expect(user.progression).to eq(3)
        expect(UserMailer).to receive(:progression_email_3).and_return(email_double)
        worker.perform
      end
    end

    describe 'batch processing behavior' do
      it 'processes users in batches using find_each' do
        expect(User).to receive(:find_each)
        worker.perform
      end

      it 'processes users in batches using find_each without error handling' do
        user1 = FactoryBot.create(:user, confirmed_at: 1.week.ago, email: 'user1@example.com')
        user2 = FactoryBot.create(:user, confirmed_at: 1.week.ago, email: 'user2@example.com')

        allow(user1).to receive(:update_reminder_freq)
        allow(user1).to receive(:needs_reminder?).and_return(false)
        allow(user2).to receive(:update_reminder_freq)
        allow(user2).to receive(:needs_reminder?).and_return(true)
        allow(user2).to receive(:progression).and_return(2)
        allow(user2).to receive(:update_attribute)

        allow(User).to receive(:find_each) do |&block|
          [user1, user2].each(&block)
        end

        # Should process both users, sending email only for user2
        expect(UserMailer).to receive(:progression_email_2).and_return(email_double)
        worker.perform
      end
    end

    describe 'logging behavior' do
      before do
        # Create a user who will receive an email
        user = FactoryBot.create(:user,
                               confirmed_at: 1.week.ago,
                               email: 'test@example.com',
                               reminder_freq: 'Weekly')
        allow(user).to receive(:needs_reminder?).and_return(true)
        allow(user).to receive(:progression).and_return(2)
        allow(user).to receive(:update_reminder_freq)
        allow(user).to receive(:update_attribute)
        allow(user).to receive(:name_or_login).and_return('Test User')
        allow(User).to receive(:find_each) do |&block|
          [user].each(&block)
        end
      end

      it 'logs email sending activity' do
        expect(Rails.logger).to receive(:info).with(/Sending progression email to Test User/)
        worker.perform
      end

      it 'logs final summary with timestamp' do
        expect(Rails.logger).to receive(:info).with(/Email reminder: Sent \d+ reminder emails at/)
        worker.perform
      end
    end


    describe 'email counter increment' do
      let(:users) do
        3.times.map do |i|
          user = FactoryBot.create(:user,
                                  confirmed_at: 1.week.ago,
                                  email: "test#{i}@example.com",
                                  reminder_freq: 'Weekly')
          allow(user).to receive(:needs_reminder?).and_return(true)
          allow(user).to receive(:progression).and_return(2)
          allow(user).to receive(:update_reminder_freq)
          allow(user).to receive(:update_attribute)
          user
        end
      end

      before do
        allow(User).to receive(:find_each) do |&block|
          users.each(&block)
        end
      end

      it 'increments email counter for each email sent' do
        expect(UserMailer).to receive(:progression_email_2).exactly(3).times.and_return(email_double)
        expect(Rails.logger).to receive(:info).with(/Sent 3 reminder emails/)
        worker.perform
      end
    end
  end
end