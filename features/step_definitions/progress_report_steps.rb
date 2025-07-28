Given /^the user with the email of "(.*)" has completed (\d+) memorization sessions in the past year$/ do |email, n|
  # Handle hardcoded email references by using the current user's email
  actual_email = email == "advanced_user@test.com" ? @current_user_email : email
  
  user = User.find_by_email(actual_email)
  if user.nil?
    raise "User with email #{actual_email} does not exist"
  end
  # n.to_i.times { |i| ProgressReport.create(:entry_date => Date.today - 1 - i, :user_id => user.id) }
  n.to_i.times { |i| FactoryBot.create(:progress_report, :entry_date => Date.today-1-i, :user_id => user.id) }
end

When /^the user with the email of "(.*)" completes a memorization session$/ do |email|
  # Handle hardcoded email references by using the current user's email
  actual_email = email == "advanced_user@test.com" ? @current_user_email : email
  
  user = User.find_by_email(actual_email)
  if user.nil?
    raise "User with email #{actual_email} does not exist"
  end
  # ProgressReport.create(:entry_date => Date.today, :user_id => user.id )
  FactoryBot.create(:progress_report, :entry_date => Date.today, :user_id => user.id)
  visit('/progress')
end
