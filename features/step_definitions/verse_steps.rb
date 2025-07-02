Given /^the following verses exist:$/ do |table|

  # table is a Cucumber::Ast::Table
	table.hashes.each do |hash|
		FactoryBot.create(:verse, hash)
	end

end

When /^I search for "(.*?)"$/ do |search_term|
  # Debug: check what verses exist in the database
  puts "=== DEBUG: Checking database for verses ==="
  verses = Verse.all
  puts "Total verses in database: #{verses.count}"
  verses.each do |verse|
    puts "Verse: #{verse.book} #{verse.chapter}:#{verse.versenum} - #{verse.text[0..50]}..."
  end
  puts "=== END DEBUG ==="
  
  step %{I fill in "js_flex-verse-search" with "#{search_term}"}
  # Trigger the search manually since observe_field might not work in test environment
  page.execute_script("mv_search('#{search_term}', displayMvSearchResultsFn);")
  sleep 2 # Wait for the search to complete
  # Debug: print the page content to see what's happening
  puts "=== DEBUG: Page content after search ==="
  puts page.html
  puts "=== END DEBUG ==="
end

