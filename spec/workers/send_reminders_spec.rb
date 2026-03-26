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
    
    # Helper method to mock User.in_batches chain
    def mock_user_find_each(users)
      batch_relation = double('batch_relation')
      ordered_batch = double('ordered_batch')
      
      # Mock the batch.reorder.each chain
      allow(batch_relation).to receive(:reorder).with(created_at: :desc).and_return(ordered_batch)
      allow(ordered_batch).to receive(:each) do |&block|
        users.each(&block)
      end
      
      allow(User).to receive(:in_batches).with(of: 100) do |&block|
        block.call(batch_relation) if block
      end
    end
    
    before do
      # Mock Rails logger to capture logging
      allow(Rails.logger).to receive(:info)
      allow(Rails.logger).to receive(:warn)
      allow(Rails.logger).to receive(:error)
      
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
        (1..120).map do |i|
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
        # Mock User.order.find_each to iterate over our test users
        mock_user_find_each(users_needing_reminders)
      end

      it 'limits emails to 4 per run due to throttle' do
        expect(UserMailer).to receive(:progression_email_2).exactly(4).times
        worker.perform
      end

      it 'logs the number of emails sent' do
        expect(Rails.logger).to receive(:info).with(/Sent 4 reminder emails/)
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
          mock_user_find_each([user])

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
        mock_user_find_each([user])

        expect(UserMailer).not_to receive(:progression_email_1)
        worker.perform
      end

      it 'logs progression email details' do
        user = FactoryBot.create(:user, base_user_attrs)
        allow(user).to receive(:progression).and_return(5)
        allow(user).to receive(:name_or_login).and_return('John Doe')
        mock_user_find_each([user])

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
        mock_user_find_each([user_with_blank_email])
        expect(user_with_blank_email).to receive(:update_reminder_freq)
        worker.perform
      end

      it 'skips users with blank email addresses' do
        allow(user_with_blank_email).to receive(:needs_reminder?).and_return(true)
        mock_user_find_each([user_with_blank_email])

        expect(UserMailer).not_to receive(:progression_email_2)
        expect(Rails.logger).to receive(:info).with(/Error: Unable to email user with id: #{user_with_blank_email.id} - blank email address/)
        
        worker.perform
      end

      it 'skips users with invalid email format' do
        user_invalid_email = FactoryBot.create(:user, 
                                             confirmed_at: 1.week.ago,
                                             reminder_freq: 'Weekly')
        # Set invalid email format that bypasses validation
        user_invalid_email.update_column(:email, 'JR')  # No @ symbol
        
        allow(user_invalid_email).to receive(:needs_reminder?).and_return(true)
        allow(user_invalid_email).to receive(:update_reminder_freq)
        mock_user_find_each([user_invalid_email])

        expect(UserMailer).not_to receive(:progression_email_2)
        expect(Rails.logger).to receive(:warn).with(/Error: Unable to email user with id: #{user_invalid_email.id} - invalid email format: 'JR'/)
        
        worker.perform
      end

      it 'skips users who do not want reminders' do
        mock_user_find_each([user_never_reminders])
        
        expect(UserMailer).not_to receive(:progression_email_2)
        worker.perform
      end

      it 'skips users who do not need reminders' do
        allow(user_no_reminder_needed).to receive(:needs_reminder?).and_return(false)
        mock_user_find_each([user_no_reminder_needed])
        
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
        mock_user_find_each([user])

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
        mock_user_find_each([user])
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
      it 'processes users in batches using in_batches' do
        expect(User).to receive(:in_batches).with(of: 100)
        worker.perform
      end

      it 'processes users in batches ordered by newest first' do
        user1 = FactoryBot.create(:user, confirmed_at: 1.week.ago, email: 'user1@example.com')
        user2 = FactoryBot.create(:user, confirmed_at: 1.week.ago, email: 'user2@example.com')

        allow(user1).to receive(:update_reminder_freq)
        allow(user1).to receive(:needs_reminder?).and_return(false)
        allow(user2).to receive(:update_reminder_freq)
        allow(user2).to receive(:needs_reminder?).and_return(true)
        allow(user2).to receive(:progression).and_return(2)
        allow(user2).to receive(:update_attribute)

        mock_user_find_each([user1, user2])

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
        mock_user_find_each([user])
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
        mock_user_find_each(users)
      end

      it 'increments email counter for each email sent' do
        expect(UserMailer).to receive(:progression_email_2).exactly(3).times.and_return(email_double)
        expect(Rails.logger).to receive(:info).with(/Sent 3 reminder emails/)
        worker.perform
      end
    end

    describe 'email sending error handling' do
      let(:user_with_email_error) do
        user = FactoryBot.create(:user,
                               confirmed_at: 1.week.ago,
                               email: 'error@example.com',
                               reminder_freq: 'Weekly')
        allow(user).to receive(:needs_reminder?).and_return(true)
        allow(user).to receive(:progression).and_return(5)
        allow(user).to receive(:update_reminder_freq)
        allow(user).to receive(:name_or_login).and_return('Test User')
        user
      end

      it 'continues processing other users when one email fails' do
        successful_user = FactoryBot.create(:user,
                                          confirmed_at: 1.week.ago,
                                          email: 'success@example.com',
                                          reminder_freq: 'Weekly')
        allow(successful_user).to receive(:needs_reminder?).and_return(true)
        allow(successful_user).to receive(:progression).and_return(2)
        allow(successful_user).to receive(:update_reminder_freq)
        allow(successful_user).to receive(:update_attribute)
        allow(successful_user).to receive(:name_or_login).and_return('Successful User')

        mock_user_find_each([user_with_email_error, successful_user])

        # Mock first email to fail
        failing_email = double('failing_email')
        expect(failing_email).to receive(:deliver).and_raise(StandardError.new('Email service error'))
        expect(UserMailer).to receive(:progression_email_5).with(user_with_email_error).and_return(failing_email)

        # Mock second email to succeed
        success_email = double('success_email')
        expect(success_email).to receive(:deliver)
        expect(UserMailer).to receive(:progression_email_2).with(successful_user).and_return(success_email)

        # Expect error logging for failed email
        expect(Rails.logger).to receive(:error).with(/Error: Failed to send progression email to user #{user_with_email_error.id}.*Email service error/)

        # Expect successful processing to continue
        expect(successful_user).to receive(:update_attribute).with(:last_reminder, Date.today)

        worker.perform
      end

      it 'logs detailed error information when email sending fails' do
        mock_user_find_each([user_with_email_error])

        failing_email = double('failing_email')
        postmark_error = StandardError.new('Invalid email address')
        expect(failing_email).to receive(:deliver).and_raise(postmark_error)
        expect(UserMailer).to receive(:progression_email_5).and_return(failing_email)

        expect(Rails.logger).to receive(:error).with(
          "** Error: Failed to send progression email to user #{user_with_email_error.id} (error@example.com): StandardError - Invalid email address"
        )

        worker.perform
      end

      it 'does not increment email counter when email sending fails' do
        mock_user_find_each([user_with_email_error])

        failing_email = double('failing_email')
        expect(failing_email).to receive(:deliver).and_raise(StandardError.new('Service error'))
        expect(UserMailer).to receive(:progression_email_5).and_return(failing_email)

        expect(Rails.logger).to receive(:info).with(/ \*\*\* Email reminder: Sent 0 reminder emails at/)
        
        worker.perform
      end

      it 'does not update last_reminder when email sending fails' do
        mock_user_find_each([user_with_email_error])

        failing_email = double('failing_email')
        expect(failing_email).to receive(:deliver).and_raise(StandardError.new('Service error'))
        expect(UserMailer).to receive(:progression_email_5).and_return(failing_email)

        expect(user_with_email_error).not_to receive(:update_attribute)

        worker.perform
      end
    end

    describe '#valid_email?' do
      it 'returns true for valid email addresses' do
        valid_emails = [
          'user@example.com',
          'test.email+tag@domain.co.uk',
          'user123@test-domain.org',
          'first.last@subdomain.example.com'
        ]

        valid_emails.each do |email|
          expect(worker.send(:valid_email?, email)).to be(true), "Expected #{email} to be valid"
        end
      end

      it 'returns false for invalid email addresses' do
        invalid_emails = [
          'JR',                    # No @ symbol (the original issue)
          '',                      # Blank
          nil,                     # Nil
          'invalid',               # No @ symbol
          '@domain.com',           # No local part
          'user@',                 # No domain
          'user..name@domain.com', # Double dots
          'user@domain',           # No TLD
          'user name@domain.com'   # Space in email
        ]

        invalid_emails.each do |email|
          expect(worker.send(:valid_email?, email)).to be(false), "Expected #{email} to be invalid"
        end
      end
    end
  end
end