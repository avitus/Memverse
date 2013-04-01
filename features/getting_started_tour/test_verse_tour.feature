Feature: Test Verse Tour
  In order to learn how to use Memverse
  A user
  Should be able to view a tour of the main memorization page

  Background:
    Given I sign in as an advanced user

    @javascript
    Scenario: User visits test_verse page for the first time
      When I go to the main memorization page
      Then I should see "Welcome to Your 1st Review Session"
      # Capybara 2.0 finds invisible links ... add this next section when we hit 2.1
      # When I click inside "a.joyride-next-tip"
      # Then I should see "The Mnemonic"

