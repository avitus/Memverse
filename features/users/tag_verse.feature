@tag_verse
Feature: Tag Verse
 In order to share thoughts on the verses
 As a user
 I want to tag verse

  Background:
    And I am a confirmed user named "Old Dog" with an email "olddog@test.com" and password "please"
    And the user named "Old Dog" has a memverse

  @javascript @tag
  Scenario: User tags with valid tag
    Given I sign in as the current user
    And I wait 1 second
    And I visit the memverse page with id <memverse_id>
    Then I should see the verse text
    When I create a tag "Fruit of the Spirit" for memverse #<memverse_id>
    Then the tag "Fruit of the Spirit" should exist for memverse #<memverse_id>
    Then the user tag table should contain "Fruit Of The Spirit"

  @javascript @tag
  Scenario: User tags with autocomplete tag
    Given I sign in as the current user
    And I visit the memverse page with id <memverse_id>
    And the tag "Fruit Of The Spirit" exists
    When I visit the memverse page with id <memverse_id>
    Then I should see the verse text
    When I create a tag "Fruit of the Spirit" for memverse #<memverse_id>
    Then the tag "Fruit of the Spirit" should exist for memverse #<memverse_id>
    Then the user tag table should contain "Fruit Of The Spirit"
