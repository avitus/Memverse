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
        | user_password              | please!123      |
        | user_password_confirmation | please!123      |
      And I press "Create my account"
      Then I should see "A MESSAGE WITH A CONFIRMATION LINK HAS BEEN SENT TO YOUR EMAIL ADDRESS. PLEASE OPEN THE LINK TO ACTIVATE YOUR ACCOUNT."
      And "user@test.com" should receive an email
      When I open the email
      Then I should see "confirm your account" in the email body
      When I follow "Confirm my account" in the email
      Then I should see "YOUR ACCOUNT WAS SUCCESSFULLY CONFIRMED."

    @javascript
    Scenario: User signs up with invalid email
      And I fill in the following:
        | user_name                  | Testy McUserton |
        | user_email                 | invalidemail    |
        | user_password              | please!123+     |
        | user_password_confirmation | please!123+     |
      Then I should see "Doesn't look like a valid email"

    @javascript
	Scenario: User signs up without password
      And I fill in the following:
        | user_name                  | Testy McUserton |
        | user_email                 | user@test.com   |
        | user_password              |                 |
        | user_password_confirmation | please!123+     |
      Then I should see "Password cannot be blank"

    @javascript
	Scenario: User signs up without password confirmation
      And I fill in the following:
        | user_name                  | Testy McUserton |
        | user_email                 | user@test.com   |
        | user_password              | please!admit3+  |
        | user_password_confirmation |                 |
      Then I should see "One more time and you're done"

    @javascript
    Scenario: User signs up with mismatched password and confirmation
      And I fill in the following:
        | user_name                  | Testy McUserton |
        | user_email                 | user@test.com   |
        | user_password              | please!123+     |
        | user_password_confirmation | please!122+     |
      Then I should see "Passwords do not match"

    @javascript
    Scenario: User signs up but misspells popular domain name
      And I fill in the following:
        | user_name                  | Testy McUsrton        |
        | user_email                 | awfulspeller@gmil.com |
        | user_password              | pleese!123+           |
        | user_password_confirmation | pleese!123+           |
      Then I should see "Did you mean awfulspeller@gmail.com"
	  When I click inside "a.email"
	  Then I should see "Didn't receive confirmation instructions?"
