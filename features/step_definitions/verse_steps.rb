Given /^the following verses exist:$/ do |table|

  # table is a Cucumber::Ast::Table
	table.hashes.each do |hash|
		FactoryBot.create(:verse, hash)
	end

end

When /^I search for "(.*?)"$/ do |search_term|
  step %{I fill in "js_flex-verse-search" with "#{search_term}"}
end

