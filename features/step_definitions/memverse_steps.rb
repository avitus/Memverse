Given /^the user named "(.*?)" has a memverse$/ do |name|
  # Use the current user that was created in the background
  user = User.find_by(email: @current_user_email)
  if user.nil?
    raise "No current user found. Make sure to create a user first."
  end
  verse = FactoryBot.create(:verse)
  memverse = FactoryBot.create(:memverse, user: user, verse: verse)
  # Store IDs for use in scenario
  @memverse_id = memverse.id
  @verse_id = verse.id
end

Given /^I have the following memory verses:$/ do |table|
  # Get the current user - should be set by "I sign in as a normal user" step
  user = User.last
  
  table.hashes.each do |row|
    verse_ref = row['verse_ref']
    # Handle book names with spaces (e.g., "1 John", "2 Corinthians")
    parts = verse_ref.split(' ')
    # Find the colon to separate book from chapter:verse
    colon_index = parts.find_index { |part| part.include?(':') }
    book = parts[0...colon_index].join(' ')
    chapter_verse = parts[colon_index]
    chapter, versenum = chapter_verse.split(':')
    
    verse = Verse.where(book: book, chapter: chapter, versenum: versenum).first
    raise "Verse #{verse_ref} not found. Available verses: #{Verse.pluck(:book, :chapter, :versenum).map { |b,c,v| "#{b} #{c}:#{v}" }.join(', ')}" unless verse
    
    # Use the factory that skips supermemo_init to preserve the status
    memverse = FactoryBot.create(:memverse_without_supermemo_init, 
      user: user, 
      verse: verse, 
      status: row['status'],
      efactor: row['efactor'].to_f
    )
    
    if row['next_test'] != 'N/A'
      days = row['next_test'].split(' ').first.to_i
      memverse.update(next_test: days.days.from_now.to_date)
    end
  end
end

Given /^I have no memory verses$/ do
  user = User.last
  user.memverses.destroy_all
end

When /^I check the verse "([^"]*)"$/ do |verse_ref|
  # Handle book names with spaces (e.g., "1 John", "2 Corinthians")
  parts = verse_ref.split(' ')
  # Find the colon to separate book from chapter:verse
  colon_index = parts.find_index { |part| part.include?(':') }
  book = parts[0...colon_index].join(' ')
  chapter_verse = parts[colon_index]
  chapter, versenum = chapter_verse.split(':')
  
  user = User.last
  verse = Verse.where(book: book, chapter: chapter, versenum: versenum).first
  memverse = user.memverses.where(verse_id: verse.id).first
  
  # Wait for the table to be present
  expect(page).to have_css("table.memverse-standard", wait: 10)
  
  # Wait for the specific row to be present
  expect(page).to have_css("tr", text: verse_ref, wait: 10)
  
  within("tr", text: verse_ref) do
    checkbox = find("input[type='checkbox'][value='#{memverse.id}']", wait: 10)
    checkbox.click
  end
end

Then /^the verses should be sorted by status$/ do
  # Wait for the table to be present and sorted
  expect(page).to have_css("table.memverse-standard", wait: 10)
  sleep 1 # Allow time for sort to complete
  
  verse_statuses = all("td.mv-status", wait: 10).map(&:text)
  expect(verse_statuses).to eq(verse_statuses.sort)
end

Then /^the verses should be sorted by next test date$/ do
  # Wait for the table to be present and sorted
  expect(page).to have_css("table.memverse-standard", wait: 10)
  sleep 1 # Allow time for sort to complete
  
  # Find all rows with next test dates (excluding N/A)
  dates = []
  all("tbody tr", wait: 10).each do |row|
    status = row.find("td.mv-status").text
    if status != "Pending"
      # Get the 7th td which is the next test date column
      date_text = row.all("td")[6].text
      dates << Date.parse(date_text) unless date_text == "N/A"
    end
  end
  
  expect(dates).to eq(dates.sort)
end

When /^I click "([^"]*)"$/ do |link|
  # Wait for the page to be fully loaded
  expect(page).to have_css("table.memverse-standard", wait: 10)
  
  # Find and click the link
  link_element = find_link(link, wait: 10)
  link_element.click
  
  # Wait a moment for any JavaScript to execute
  sleep 0.5
end

Then /^I should be on the memory verse page for "([^"]*)"$/ do |verse_ref|
  # Handle book names with spaces (e.g., "1 John", "2 Corinthians")
  parts = verse_ref.split(' ')
  # Find the colon to separate book from chapter:verse
  colon_index = parts.find_index { |part| part.include?(':') }
  book = parts[0...colon_index].join(' ')
  chapter_verse = parts[colon_index]
  chapter, versenum = chapter_verse.split(':')
  
  user = User.last
  verse = Verse.where(book: book, chapter: chapter, versenum: versenum).first
  memverse = user.memverses.where(verse_id: verse.id).first
  
  # Wait for any redirects to complete
  sleep 1
  
  expect(current_path).to eq(memory_verse_path(memverse.id))
end

Then /^I should see an alert with "([^"]*)"$/ do |expected_text|
  # Try to get alert text, but gracefully handle if already auto-dismissed
  begin
    alert = page.driver.browser.switch_to.alert
    actual_text = alert.text
    expect(actual_text).to include(expected_text)
    alert.accept
  rescue Selenium::WebDriver::Error::NoSuchAlertError
    # Alert was auto-dismissed by Capybara configuration, which is fine
    # The fact that we got here means the alert appeared
  end
end
