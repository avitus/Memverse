Given /^I have completed (\d+) memorization sessions in the past year$/ do |n|
  n.to_i.times { |i| ProgressReport.create(:entry_date => Date.today - 1 - i) }
end

When /^I complete a memorization session$/ do
  ProgressReport.create(:entry_date => Date.today)
  visit('/progress')
end
