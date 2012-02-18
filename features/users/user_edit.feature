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