Feature: Delete account
  To protect privacy and comply with GDPR
  A signed in user
  Should be able to delete account

    Scenario: User deletes account
      Given I sign in as a normal user
      And I delete account
      Then I should see "Signed out"
      When I return next time
      Then I should be unable to sign in