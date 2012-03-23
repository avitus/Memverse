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
        | user_name                  | Testy McUserton |
        | user_email                 | user@test.com   |
        | user_password              | please          |
        | user_password_confirmation | please          |
      And I press "submit"
      Then I should see "A message with a confirmation link has been sent to your email address. Please open the link to activate your account."
      And "user@test.com" should receive an email
      When I open the email
      Then I should see "confirm your account" in the email body
      When I follow "Confirm my account" in the email
      Then I should be signed in
    
    @javascript
    Scenario: User signs up with invalid email
      And I fill in the following:
        | user_name                  | Testy McUserton |
        | user_email                 | invalidemail    |
        | user_password              | please          |
        | user_password_confirmation | please          |
      Then I should see "Doesn't look like a valid email"

    @javascript
	Scenario: User signs up without password
      And I fill in the following:
        | user_name                  | Testy McUserton |
        | user_email                 | user@test.com   |
        | user_password              |                 |
        | user_password_confirmation | please          |
      Then I should see "Password cannot be blank"

    @javascript
	Scenario: User signs up without password confirmation
      And I fill in the following:
        | user_name                  | Testy McUserton |
        | user_email                 | user@test.com   |
        | user_password              | please          |
        | user_password_confirmation |                 |
      Then I should see "Passwords do not match"

    @javascript
    Scenario: User signs up with mismatched password and confirmation
      And I fill in the following:
        | user_name                  | Testy McUserton |
        | user_email                 | user@test.com   |
        | user_password              | please          |
        | user_password_confirmation | please1         |
      Then I should see "Passwords do not match"

    @javascript
    Scenario: User signs up but misspells popular domain name
      And I fill in the following:
        | user_name                  | Testy McUserton |
        | user_email                 | user@gmal.com   |
        | user_password              | please          |
        | user_password_confirmation | please          |
      Then I should see "Did you mean user@gmail.com"
	  When I click inside "a.email"
	  Then I should see "We will email you a confirmation"
	  