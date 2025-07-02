Feature: Learn a Verse
  In order to get started on a new verse
  A user
  Should be able to repeatedly type the same verse while words are removed

  Background:
    Given I sign in as an advanced user

    @javascript
    Scenario: User learns a verse
      When I go to the learn verse page
      # The default Verse factory uses text from Gal 2:1 for all verses
      And I search for "Galatians 2:1"
      Then I should see "But the fruit of"
      When I click inside "div.select-verse-button"
      Then I should see "love, joy, peace, patience, kindness"
      When I advance 4 learning levels
      Then I should see "love, joy"
      And I should not see "patience, kindness"
      When I fill in "Spirit" with "spirit"
      Then I should see "the fruit of the Spirit is love, joy"

