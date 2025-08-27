namespace :memverse do
  desc "Find and fix users with invalid email addresses"
  task fix_invalid_emails: :environment do
    puts "Finding users with invalid email addresses..."
    
    # Email validation method (same as in SendReminders worker)
    def valid_email?(email)
      return false if email.blank?
      
      # Basic email format validation - must contain @ and have reasonable format
      return false unless email.include?('@')
      return false if email.include?(' ')  # No spaces allowed
      return false if email.include?('..') # No double dots allowed
      return false if email.start_with?('@') || email.end_with?('@')
      
      # Split on @ - should have exactly 2 parts
      parts = email.split('@')
      return false unless parts.length == 2
      
      local_part, domain_part = parts
      return false if local_part.empty? || domain_part.empty?
      return false unless domain_part.include?('.') # Domain must have at least one dot
      
      # Basic format check with regex for more complex validation
      email_regex = /\A[a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*\z/
      email.match?(email_regex)
    end
    
    invalid_users = []
    total_users = User.count
    
    puts "Checking #{total_users} users..."
    
    User.find_each.with_index do |user, index|
      if index % 1000 == 0
        puts "Processed #{index}/#{total_users} users..."
      end
      
      unless valid_email?(user.email)
        invalid_users << {
          id: user.id,
          email: user.email,
          name: user.name,
          login: user.login,
          created_at: user.created_at,
          last_activity_date: user.last_activity_date
        }
      end
    end
    
    puts "\n" + "="*60
    puts "INVALID EMAIL ADDRESSES FOUND:"
    puts "="*60
    
    if invalid_users.empty?
      puts "✅ No users with invalid email addresses found!"
    else
      puts "❌ Found #{invalid_users.length} users with invalid email addresses:\n"
      
      invalid_users.each do |user_data|
        puts "ID: #{user_data[:id]}"
        puts "  Email: '#{user_data[:email]}'"
        puts "  Name: #{user_data[:name]}"
        puts "  Login: #{user_data[:login]}"
        puts "  Created: #{user_data[:created_at]}"
        puts "  Last Activity: #{user_data[:last_activity_date] || 'Never'}"
        puts "  " + "-" * 40
      end
      
      puts "\n" + "="*60
      puts "RECOMMENDATIONS:"
      puts "="*60
      puts "1. Review these users and determine if they are legitimate accounts"
      puts "2. For users with obvious typos (like 'JR' instead of 'jr@example.com'):"
      puts "   - Contact them through other means if possible"
      puts "   - Ask them to update their email address via profile settings"
      puts "3. For users with clearly fake/invalid emails:"
      puts "   - Consider setting their email to nil and marking them for cleanup"
      puts "   - Use: User.find(ID).update_column(:email, nil)"
      puts "4. For inactive users with invalid emails (no recent activity):"
      puts "   - Consider deleting these accounts if they haven't been active"
      puts "\n"
      
      # Show some statistics
      recent_activity = invalid_users.select { |u| u[:last_activity_date] && u[:last_activity_date] > 1.month.ago }
      old_activity = invalid_users.select { |u| u[:last_activity_date] && u[:last_activity_date] <= 1.month.ago }
      never_active = invalid_users.select { |u| u[:last_activity_date].nil? }
      
      puts "BREAKDOWN:"
      puts "- Recently active (last 30 days): #{recent_activity.length}"
      puts "- Old activity (>30 days ago): #{old_activity.length}"
      puts "- Never active: #{never_active.length}"
    end
    
    puts "\n✅ Task completed!"
  end
end