Given /^the user with the email of "(.*)" has completed (\d+) memorization sessions in the past year$/ do |email, n|
  user = User.find_by_email(email)
  # n.to_i.times { |i| ProgressReport.create(:entry_date => Date.today - 1 - i, :user_id => user.id) }
  n.to_i.times { |i| FactoryBot.create(:progress_report, :entry_date => Date.today-1-i, :user_id => user.id) }
end

When /^the user with the email of "(.*)" completes a memorization session$/ do |email|
  user = User.find_by_email(email)
  # ProgressReport.create(:entry_date => Date.today, :user_id => user.id )
  FactoryBot.create(:progress_report, :entry_date => Date.today, :user_id => user.id)
  visit('/progress')
end
