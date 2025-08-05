Given /^the following verses exist:$/ do |table|

  # table is a Cucumber::Ast::Table
	table.hashes.each do |hash|
		FactoryBot.create(:verse, hash)
	end

end

When /^I search for "(.*?)"$/ do |search_term|
  step %{I fill in "js_flex-verse-search" with "#{search_term}"}
  # Get user's translation and trigger the search manually since observe_field might not work in test environment
  page.execute_script("tl = $('#translation').data('tl'); flexversesearch('#{search_term}');")
  sleep 3 # Wait for the search to complete
end

