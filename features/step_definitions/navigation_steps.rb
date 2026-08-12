# Steps for the top navigation menu and its submenus

Then /^the Review submenu should contain a "([^"]*)" link to "([^"]*)"$/ do |text, href|
  within('#memory') do
    expect(page).to have_link(text, href: href)
  end
end
