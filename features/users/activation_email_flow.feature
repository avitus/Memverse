Feature: Account Activation Email Flow
  As a user who just confirmed their account
  I want to receive an activation confirmation email
  So that I know my account is now fully active

  Background:
    Given the following translations exist:
      | name   | translation        | language | translation_code |
      | NASB95 | New American Bible | English  | NASB95           |
    And email deliveries are enabled

  @javascript 
  Scenario: User receives activation email after confirming account
    Given I am not logged in
    And no user exists with an email of "activate@test.com"
    When I go to the sign up page
    And I fill in the following:
      | user_login                 | activateuser    |
      | user_name                  | Activate User   |
      | user_email                 | activate@test.com |
      | user_password              | password123     |
      | user_password_confirmation | password123     |
    And I select "New American Bible" from "user_bible_translation_id"
    And I press "Sign up"
    Then "activate@test.com" should receive an email
    When I open the email
    And I follow "Confirm my account" in the email
    Then I should see "Your email address has been successfully confirmed"
    And "activate@test.com" should receive 2 emails
    When I open the email with subject "Your Memverse account has been activated!"
    Then I should see "Activate User" in the email body
    And I should see "admin@memverse.com" in the email from
    And the email should have tag "account-activation"
    And the email should have message stream "outbound"
    And the email should have unsubscribe link

  @javascript
  Scenario: Activation email contains proper Postmark headers
    Given I am not logged in
    And no user exists with an email of "activation-headers@test.com"
    When I go to the sign up page
    And I fill in the following:
      | user_login                 | activationheader |
      | user_name                  | Activation Header |
      | user_email                 | activation-headers@test.com |
      | user_password              | password123     |
      | user_password_confirmation | password123     |
    And I select "New American Bible" from "user_bible_translation_id"
    And I press "Sign up"
    Then "activation-headers@test.com" should receive an email
    When I open the email
    And I follow "Confirm my account" in the email
    Then "activation-headers@test.com" should receive 2 emails
    When I open the email with subject "Your Memverse account has been activated!"
    Then the email should have correct Postmark configuration:
      | tag            | account-activation |
      | message_stream | outbound          |
      | from           | "Memverse" <admin@memverse.com> |

  @javascript
  Scenario: Activation email includes unsubscribe functionality
    Given I am not logged in
    And no user exists with an email of "activation-unsub@test.com"
    When I go to the sign up page
    And I fill in the following:
      | user_login                 | activationunsub |
      | user_name                  | Activation Unsub |
      | user_email                 | activation-unsub@test.com |
      | user_password              | password123     |
      | user_password_confirmation | password123     |
    And I select "New American Bible" from "user_bible_translation_id"
    And I press "Sign up"
    Then "activation-unsub@test.com" should receive an email
    When I open the email
    And I follow "Confirm my account" in the email
    Then "activation-unsub@test.com" should receive 2 emails
    When I open the email with subject "Your Memverse account has been activated!"
    Then the email should have header "List-Unsubscribe" containing "https://memverse.com/unsubscribe/activation-unsub@test.com"
    And the email should have header "List-Unsubscribe-Post" containing "List-Unsubscribe=One-Click"

  Scenario: No activation email when account confirmation fails
    Given I have a user "failuser" with email "fail@test.com" and password "password123" 
    And the user "failuser" is not confirmed
    And email deliveries are enabled
    When I visit an invalid confirmation link for "fail@test.com"
    Then I should see "Confirmation token is invalid"
    And "fail@test.com" should receive only the signup email

  @javascript
  Scenario: Only one activation email sent per confirmation
    Given I am not logged in
    And no user exists with an email of "single-activation@test.com"
    When I go to the sign up page
    And I fill in the following:
      | user_login                 | singleactivation |
      | user_name                  | Single Activation |
      | user_email                 | single-activation@test.com |
      | user_password              | password123     |
      | user_password_confirmation | password123     |
    And I select "New American Bible" from "user_bible_translation_id"
    And I press "Sign up"
    Then "single-activation@test.com" should receive an email
    When I open the email
    And I follow "Confirm my account" in the email
    Then "single-activation@test.com" should receive exactly 2 emails total
    When the user "singleactivation" updates their name to "Updated Name"
    Then "single-activation@test.com" should still receive exactly 2 emails total

  @javascript
  Scenario: Activation email content verification
    Given I am not logged in
    And no user exists with an email of "activation-content@test.com"
    When I go to the sign up page
    And I fill in the following:
      | user_login                 | activationcontent |
      | user_name                  | Activation Content |
      | user_email                 | activation-content@test.com |
      | user_password              | password123     |
      | user_password_confirmation | password123     |
    And I select "New American Bible" from "user_bible_translation_id"
    And I press "Sign up"
    Then "activation-content@test.com" should receive an email
    When I open the email
    And I follow "Confirm my account" in the email
    Then "activation-content@test.com" should receive 2 emails
    When I open the email with subject "Your Memverse account has been activated!"
    Then I should see "Your Memverse account has been activated!" in the email subject
    And I should see "Activation Content" in the email body
    And the email should be multipart with HTML and text versions
    And both email parts should contain "Activation Content"

  Scenario: Activation email delivery in test environment
    Given email deliveries are disabled for testing
    And I have a user "testactivation" with email "test-activation@test.com" and password "password123" 
    And the user "testactivation" is not confirmed
    When the user "testactivation" confirms their account
    Then "test-activation@test.com" should receive no emails