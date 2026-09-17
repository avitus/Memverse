Feature: Forgot password
  In order to continue memorizing when I forget my password
  As a user
  I want to be able to retrieve it via email

    Background:
      Given I am not logged in

    Scenario: User enters wrong password and requests to reset
      Given I am a confirmed user named "forgetful" with an email "amnesiac@test.com" and password "easytoforget"
      And all emails have been delivered
      When I go to the sign in page
      And I sign in as "amnesiac@test.com/wrongpassword"
      Then I should see "Invalid email or password."
      When I follow "Forgot your password?"
      And I fill in the following:
        | user_email   | amnesiac@test.com    |
      And I press "Send me reset password instructions"
      Then I should see "If a Memverse account exists for that exact email address, you will receive password reset instructions in a few minutes."
      And "amnesiac@test.com" should receive an email with subject "Reset password instructions"
      When I open the email
      Then I should see "Someone has requested a link to change your password, and you can do this through the link below." in the email body
      When I follow "Change my password" in the email
      Then I should see "Change your password"
      When I fill in the following:
        | user_password              | yay_back_in     |
        | user_password_confirmation | yay_back_in     |
      And I press "Change my password"
      Then I should see "Choose your translation"

    Scenario: User requests a reset for an unknown email address
      When I go to the sign in page
      And I follow "Forgot your password?"
      And I fill in "user_email" with "unknown@example.com"
      And I press "Send me reset password instructions"
      Then I should see "If a Memverse account exists for that exact email address, you will receive password reset instructions in a few minutes."
      And I should see "If no message arrives, check your spam folder and verify the address you entered."
      And I should not see "prohibited this user from being saved"
