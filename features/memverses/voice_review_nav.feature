Feature: Voice Review navigation
  In order to review verses by speaking them
  A user
  Should be able to reach Voice Review from the Review menu

  Scenario: Voice Review link routes to the voice review page
    Given I sign in as a normal user
    When I follow "Voice Review"
    Then I should see "You need to add some verses first."
