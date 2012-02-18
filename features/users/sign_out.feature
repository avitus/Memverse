Feature: Sign out
  To protect my account from unauthorized access
  A signed in user
  Should be able to sign out

    Scenario: User signs out
      Given I sign in as a normal user
      And I sign out
      Then I should see "Signed out"
      When I return next time
      Then I should be signed out
