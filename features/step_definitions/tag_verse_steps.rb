Then /^the user tag table should contain "(.*?)"$/ do |value|
  expect(page).to have_css("#list-of-user-tags", :visible => /#{value}/ )
end
