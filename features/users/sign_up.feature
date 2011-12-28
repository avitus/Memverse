Feature: Sign up
  In order to get access to protected sections of the site
  As a user
  I want to be able to sign up

    Background:
      Given I am not logged in
      And I am on the home page
      And I go to the sign up page

    @javascript
    Scenario: User signs up with valid data
      And I fill in the following:
        | user[name]                  | Testy McUserton |
        | user[email]                 | user@test.com   |
        | user[password]              | please          |
        | user[password_confirmation] | please          |
      And I press "commit"
      Then I should see "Welcome! You have signed up successfully."
      And "user@test.com" should receive an email
      And I open the email
      And I should see "activate your account"
      And I follow "confirm"
      Then I should see "Your account was successfully confirmed. Please sign in to continue."
      And "user@test.com" should receive an email
      And I open the email
      And I should see "your account has been activated"
    
    @javascript
    Scenario: User signs up with invalid email
      And I fill in the following:
        | user_name                  | Testy McUserton |
        | user_email                 | invalidemail    |
        | user_password              | please          |
        | user_password_confirmation | please          |
      And I press "commit"
      Then I should see "Email is invalid"

    Scenario: User signs up without password
      And I fill in the following:
        | Name                  | Testy McUserton |
        | Email                 | user@test.com   |
        | Password              |                 |
        | Password confirmation | please          |
      And I press "Sign up"
      Then I should see "Password can't be blank"

    Scenario: User signs up without password confirmation
      And I fill in the following:
        | Name                  | Testy McUserton |
        | Email                 | user@test.com   |
        | Password              | please          |
        | Password confirmation |                 |
      And I press "Sign up"
      Then I should see "Password doesn't match confirmation"

    Scenario: User signs up with mismatched password and confirmation
      And I fill in the following:
        | Name                  | Testy McUserton |
        | Email                 | user@test.com   |
        | Password              | please          |
        | Password confirmation | please1         |
      And I press "Sign up"
      Then I should see "Password doesn't match confirmation"

