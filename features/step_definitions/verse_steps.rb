Given /^the following verses exist:$/ do |table|
  # table is a Cucumber::Ast::Table
  table.hashes.each do |hash|
    # Map verse_number to versenum since that's the actual field name
    if hash['verse_number']
      hash['versenum'] = hash.delete('verse_number')
    end
    FactoryBot.create(:verse, hash)
  end
end

When /^I search for "(.*?)"$/ do |search_term|
  step %{I fill in "js_flex-verse-search" with "#{search_term}"}
  # Different pages use different search functions
  if page.current_path == '/learn'
    # Learn page uses mv_search with displayMvSearchResultsFn callback
    page.execute_script("mv_search('#{search_term}', displayMvSearchResultsFn);")
  else
    # Add verse page uses flexversesearch
    page.execute_script("tl = $('#translation').data('tl'); flexversesearch('#{search_term}');")
  end
  sleep 3 # Wait for the search to complete
end

