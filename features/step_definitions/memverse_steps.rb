Given /^I am logged in as "([^\"]*)" with password "([^\"]*)"$/ do |login, password|  
  unless login.blank?  
    visit login_url  
    fill_in "login", :with => login  
    fill_in "password", :with => password  
    click_button "Login"  
  end  
end 

When /^I log in as "([^\"]*)" with password "([^\"]*)"$/ do |login, password|
  unless login.blank?  
    visit login_url  
    fill_in "login", :with => login  
    fill_in "password", :with => password  
    click_button "Login"  
  end 
end

When /^I register as "([^\"]*)" with email "([^\"]*)" and password "([^\"]*)"$/ do |login, email, password|
  unless login.blank?  
    visit signup_url  
    fill_in "Username",               :with => login  
    fill_in "Email",                  :with => email    
    fill_in "Password",               :with => password  
    fill_in "Password Confirmation",  :with => password      
    click_button "Sign up"  
  end 
end
