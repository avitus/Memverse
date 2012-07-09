Feature: Edit User
  As a registered user of the website
  I want to edit my user profile
  so I can change my name

    Scenario: I sign in and edit my account
      Given I sign in as a normal user
      When I follow "Profile"
      And I fill in "user_name" with "New Name"
      And I press "Update Profile"
      And I go to the homepage
      Then I should see "Welcome: New Name"
      
    Scenario: I sign in and change my email address
      Given I sign in as a normal user
      When I follow "Profile"
      And I fill in "user_email" with "new_email@memverse.com"
      And I press "Update Profile"
      And I go to the homepage
      Then "new_email@memverse.com" should receive an email
      When I open the email
      Then I should see "confirm your account" in the email body
      When I follow "Confirm my account" in the email
      Then I should be signed in
      When I follow "Profile"   
      Then the "user_email" field should contain "new_email@memverse.com"     