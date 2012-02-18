Feature: Sign in
  In order to get access to protected sections of the site
  A user
  Should be able to sign in
  
    Background:
      Given I am not logged in

    Scenario: User is not signed up
      Given no user exists with an email of "user@test.com"
      When I go to the sign in page
      And I sign in as "user@test.com/please"
      Then I should see "Invalid email or password."
      And I go to the home page
      And I should be signed out

    Scenario: User enters wrong password
      Given I am a user named "foo" with an email "user@test.com" and password "please"
      When I go to the sign in page
      And I sign in as "user@test.com/wrongpassword"
      Then I should see "Invalid email or password."
      And I go to the home page
      And I should be signed out

    Scenario: User signs in successfully with email
      Given I sign in as a normal user
      Then I should see "Choose your translation"
      And I should be signed in
      When I return next time
      Then I should be already signed in
           
    Scenario: User who has already added verses signs in
    Given the following verses exist:
      |id | translation | book_index | book    | chapter | versenum | text                                                    |
      | 1 | NIV         | 1          | Genesis | 1       | 1        | In the beginning God created the heavens and the earth  |
      | 2 | NIV         | 1          | Genesis | 1       | 2        | Now the earth was formless and void                     |
    And the following user exists:
	  | name    | email             | password |
      | Old Dog | olddog@test.com   | please   |
    And the following memverses exist:
      | User          | Verse |
      | name: Old Dog | id: 1 |
      | name: Old Dog | id: 2 |
    And the email address "olddog@test.com" is confirmed
    When I go to the sign in page
    And I sign in as "olddog@test.com/please"
    Then I should be signed in
    When I return next time
    Then I should be already signed in    
      
    Scenario: User account is not confirmed
      Given I am a user named "unconfirmed" with an email "user@test.com" and password "please"
      And the email address "user@test.com" is not confirmed
      When I go to the sign in page
      And I sign in as "user@test.com/please"
      Then I should see "You have to confirm your account before continuing."
      And I should be signed out
