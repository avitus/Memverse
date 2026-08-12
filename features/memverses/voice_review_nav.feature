Feature: Voice Review navigation
  In order to review verses by speaking them
  A user
  Should be able to reach Voice Review from the Review menu

  Scenario: Review submenu links to Voice Review
    Given I sign in as a normal user
    When I go to the home page
    Then the Review submenu should contain a "Voice Review" link to "/voice_review"

  Scenario: Voice Review link routes to the voice review page
    Given I sign in as a normal user
    When I follow "Voice Review"
    Then I should see "You need to add some verses first."
