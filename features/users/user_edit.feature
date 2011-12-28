Feature: Edit User
  As a registered user of the website
  I want to edit my user profile
  so I can change my name

    Scenario: I sign in and edit my account
      Given I am a user named "foo" with an email "user@test.com" and password "please"
      And the email address "user@test.com" is confirmed
      When I sign in as "user@test.com/please"
      Then I should be signed in
      When I follow "Profile"
      And I fill in "user_name" with "baz"
      And I press "Update Profile"
      And I go to the homepage
      Then I should see "Welcome: baz"