Given /^no user exists with an email of "(.*)"$/ do |email|
  User.find(:first, :conditions => { :email => email }).should be_nil
end

Given /^I am a user named "([^"]*)" with an email "([^"]*)" and password "([^"]*)"$/ do |name, email, password|
  FactoryGirl.create(:user, :name => name,
                     :email => email,
                     :password => password,
                     :password_confirmation => password)
end

Given /^I am a confirmed user named "([^"]*)" with an email "([^"]*)" and password "([^"]*)"$/ do |name, email, password|
  User.new(:name => name,
            :email => email,
            :password => password,
            :password_confirmation => password).confirm!
end

Then /^I should be already signed in$/ do
  And %{I should see "Logout"}
end

Given /^I am signed up as "(.*)\/(.*)"$/ do |email, password|
  Given %{I am not logged in}
  When %{I go to the sign up page}
  And %{I fill in "user[name]" with "My Name"}
  And %{I fill in "user[email]" with "#{email}"}
  And %{I fill in "user[password]" with "#{password}"}
  And %{I fill in "user[password_confirmation]" with "#{password}"}
  And %{I press "signupbutton"}
  Then %{I should see "You have signed up successfully. If enabled, a confirmation was sent to your e-mail."}
  And %{I am logout}
end

Then /^I sign out$/ do
  visit('/users/sign_out')
end

Given /^I am logout$/ do
  Given %{I sign out}
end

Given /^I am not logged in$/ do
  Given %{I sign out}
end

When /^I sign in as "(.*)\/(.*)"$/ do |email, password|
  Given %{I am not logged in}
  When %{I go to the sign in page}
  And %{I fill in "user[email]" with "#{email}"}
  And %{I fill in "user[password]" with "#{password}"}
  And %{I press "signinbutton"}
end

Then /^I should be signed in$/ do
  Then %{I should see "Logout"}
end

When /^I return next time$/ do
  And %{I go to the home page}
end

Then /^I should be signed out$/ do
  And %{I should see "SIGN UP"}
  And %{I should see "LOG IN"}
  And %{I should not see "Logout"}
end

Given /^the email address "(.*)" is confirmed$/ do |email|
  User.find_by_email(email).confirm!
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
  referring_id = User.find_by_email(email).referred_by
  User.find(referring_id).login == login
end

Given /^the user with the email address "([^"]*)" can blog$/ do |email|
  # class User < ActiveRecord::Base
  #   def can_blog?
  #     self.id == User.find_by_email(email).id
  #  end
  # end
end

Given /^a blog titled "(.*)"$/ do |title|
  Blog.new(:title => title, :url_identifier => "main").save!
end

Given /^I sign in as a normal user$/ do
  Given %{I am a user named "normal" with an email "user@test.com" and password "please"}
  And %{the email address "user@test.com" is confirmed}
  When %{I sign in as "user@test.com/please"}
  Then %{I should be signed in}
end

Given /^I sign in as an advanced user$/ do
  Given %{I am a user named "advanced" with an email "advanced_user@test.com" and password "please"}
  And %{the email address "advanced_user@test.com" is confirmed}
  And %{the user with the email of "advanced_user@test.com" has 10 verses in his list}
  When %{I sign in as "advanced_user@test.com/please"}
  Then %{I should be signed in}
end

Given /^the user with the email of "(.*)" has (\d+) verses in his list$/ do |email, n|
  user = User.find_by_email(email)
  n.to_i.times { |i| 
    vs = FactoryGirl.create(:verse, :chapter => 20, :versenum => i)
    FactoryGirl.create(:memverse, :user_id => user.id, :verse_id => vs.id) 
  }
end


Then /^the tag "(.*)" should exist for memverse #([0-9]+)$/ do |tagname, id|
  mv = Memverse.find(id)
  mv.tags.include? tagname
end

When /^I type in "([^\"]*)" into autocomplete list "([^\"]*)" and I choose "([^\"]*)"$/ do |typed, input_name,should_select|
   page.driver.browser.execute_script %Q{ $('input[data-autocomplete]').trigger("focus") }
   fill_in("#{input_name}",:with => typed)
   page.driver.browser.execute_script %Q{ $('input[data-autocomplete]').trigger("keydown") }
   sleep 1
   page.driver.browser.execute_script %Q{ $('.ui-menu-item a:contains("#{should_select}")').trigger("mouseenter").trigger("click"); }
end
