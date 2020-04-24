def wait_for_input
  Timeout.timeout(Capybara.default_max_wait_time) do
    loop until page.has_css?("td.edit_mv input")
  end
end

Given /^no user exists with an email of "(.*)"$/ do |email|
  User.where(:email => email).first.should be_nil
end

Given /^I am a user named "([^"]*)" with an email "([^"]*)" and password "([^"]*)"$/ do |name, email, password|
  FactoryBot.create(:user, :name => name,
                     :email => email,
                     :password => password,
                     :password_confirmation => password)
end

Given /^I am an admin named "([^"]*)" with an email "([^"]*)" and password "([^"]*)"$/ do |name, email, password|
  FactoryBot.create(:user, :name => name,
                     :email => email,
                     :password => password,
                     :password_confirmation => password,
                     :admin => true )
end

Given /^I am a confirmed user named "([^"]*)" with an email "([^"]*)" and password "([^"]*)"$/ do |name, email, password|
  User.new(:name => name,
            :email => email,
            :password => password,
            :password_confirmation => password).confirm
end

Given /^I am an advanced user named "([^"]*)" with an email "([^"]*)" and password "([^"]*)"$/ do |name, email, password|
  FactoryBot.create(:user, :name => name,
                     :email => email,
                     :password => password,
                     :password_confirmation => password,
                     :memorized => 100,
                     :learning  =>  20)
end


Then /^I should be already signed in$/ do
  step %{I should see "Logout"}
end

Given /^I am signed up as "(.*)\/(.*)"$/ do |email, password|
  step %{I am not logged in}
  step %{I go to the sign up page}
  step %{I fill in "user[name]" with "My Name"}
  step %{I fill in "user[email]" with "#{email}"}
  step %{I fill in "user[password]" with "#{password}"}
  step %{I fill in "user[password_confirmation]" with "#{password}"}
  step %{I press "signupbutton"}
  step %{I should see "You have signed up successfully. If enabled, a confirmation was sent to your e-mail."}
  step %{I am logout}
end

Then /^I sign out$/ do
  current_driver = Capybara.current_driver
  begin
    Capybara.current_driver = :rack_test
    page.driver.submit :delete, "/users/sign_out", {}
  ensure
    Capybara.current_driver = current_driver
  end
end

Given /^I am not logged in$/ do
  current_driver = Capybara.current_driver
  begin
    Capybara.current_driver = :rack_test
    page.driver.submit :delete, "/users/sign_out", {}
  ensure
    Capybara.current_driver = current_driver
  end
end

When /^I sign in as "(.*)\/(.*)"$/ do |email, password|
  step %{I am not logged in}
  step %{I go to the sign in page}
  step %{I fill in "user[email]" with "#{email}"}
  step %{I fill in "user[password]" with "#{password}"}
  step %{I press "signinbutton"}
end

Then /^I should be signed in$/ do
  step %{I should see "Logout"}
end

When /^I return next time$/ do
  step %{I go to the home page}
end

Then /^I should be signed out$/ do
  step %{I should see "SIGN UP"}
  step %{I should see "LOG IN"}
  step %{I should not see "Logout"}
end

Given /^the email address "(.*)" is confirmed$/ do |email|
  User.find_by_email(email).confirm
end

Given /^the email address "(.*)" is not confirmed$/ do |email|
  !User.find_by_email(email).confirmed?
end

Given /^a user with the login of "(.*)"$/ do |login|
  User.new(:name => "Test User",
           :email => "testemail@test.com",
           :login => login,
           :password => "secret",
           :password_confirmation => "secret").save!
end

Then /^there should be a user with an email of "(.*)" whose referrer's login is "(.*)"$/ do |email, login|
  referring_id = User.where(:email => email).first.referred_by
  User.find(referring_id).login == login
end

Given /^the user with the email address "([^"]*)" can blog$/ do |email|
  # class User < ActiveRecord::Base
  #   def can_blog?
  #     self.id == User.where(:email => email).first.id
  #  end
  # end
end

Given /^a blog titled "(.*)"$/ do |title|
  Bloggity::Blog.new(:title => title, :url_identifier => "main").save!
end

Given /^I sign in as a normal user$/ do
  step %{I am a user named "normal" with an email "user@test.com" and password "please"}
  step %{the email address "user@test.com" is confirmed}
  step %{I sign in as "user@test.com/please"}
  step %{I should be signed in}
end

Given /^I sign in as a non-blogging user$/ do
  step %{I am a user named "blognot" with an email "blognot@test.com" and password "please"}
  @u = User.find_by_email("blognot@test.com")
  @u.id = 1000
  @u.save
  step %{the email address "blognot@test.com" is confirmed}
  step %{I sign in as "blognot@test.com/please"}
  step %{I should be signed in}
end

Given /^I sign in as an advanced user$/ do
  step %{I am an advanced user named "advanced" with an email "advanced_user@test.com" and password "please"}
  step %{the email address "advanced_user@test.com" is confirmed}
  step %{the user with the email of "advanced_user@test.com" has 10 verses in his list}
  step %{I sign in as "advanced_user@test.com/please"}
  step %{I should be signed in}
end

Given /^I sign in as an admin user$/ do
  step %{I am an admin named "admin" with an email "admin@test.com" and password "superuser"}
  step %{the email address "admin@test.com" is confirmed}
  step %{I sign in as "admin@test.com/superuser"}
  step %{I should be signed in}
end

Given /^the user with the email of "(.*)" has (\d+) verses in his list$/ do |email, n|
  user = User.find_by_email(email)
  n.to_i.times { |i|
    vs = FactoryBot.create(:verse, chapter: 2, versenum: i+1)
    FactoryBot.create(:memverse, :user_id => user.id, :verse_id => vs.id)
  }
  user.memorized = 10
  user.save
end

Then /^the tag "(.*)" should exist for memverse #([0-9]+)$/ do |tagname, id|
  mv = Memverse.find(id)
  mv.tags.include? tagname
end

When /^I type in "([^\"]*)" and I choose "([^\"]*)"$/ do |typed, should_select|
  wait_for_input
  input = find("td.edit_mv input")
  input.native.send_keys typed
  sleep 5
  page.driver.browser.execute_script %Q{ $('.ui-menu-item a:contains("#{should_select}")').animate({opacity:0.4},1500); }
  page.driver.browser.execute_script %Q{ $('.ui-menu-item a:contains("#{should_select}")').trigger("mouseenter").trigger("click"); }
  sleep 5
end

When /^I type "([^\"]*)"$/ do |typed|
  wait_for_input
  input = find("td.edit_mv input")
  input.native.send_keys typed
end

When /^I sleep for ([0-9]+)$/ do |time|
   sleep time.to_i
end
