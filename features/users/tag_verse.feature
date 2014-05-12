@tag_verse
Feature: Tag Verse
 In order to share thoughts on the verses
 As a user
 I want to tag verse

  Background:
    Given the following verses exist:
      |id | translation | book_index | book    | chapter | versenum | text                                                    |
      | 1 | NIV         | 1          | Genesis | 1       | 1        | In the beginning God created the heavens and the earth  |
    And I am a confirmed user named "Old Dog" with an email "olddog@test.com" and password "please"
    And the user named "Old Dog" has a memverse with the id of 1

    @javascript
    Scenario: User tags with valid tag
    Given I sign in as "olddog@test.com/please"
      And I go to the page for the memverse with the id of 1
	  Then I should see "But the fruit of the Spirit"
	  When I click inside "td.edit_mv"
      And I sleep for 2
      And I fill in "input" with "Fruit of the Spirit"
      And I submit the form
      Then I should see "Fruit of the Spirit" within "#user-tags"

    # @javascript
    # Scenario: User tags with duplicate tag
    # Given I sign in as "olddog@test.com/please"
    #   And I go to the page for the memverse with the id of 1
    #   And I have tag: Fruit of the Spirit
    # When I click inside ".edit_mv"
	  #   And I type in "Crea" into autocomplete list "input" and I choose "Fruit of the Spirit"
    # Then I should get an error

    @javascript
    Scenario: User tags with autocomplete tag
      Given I sign in as "olddog@test.com/please"
        And I go to the page for the memverse with the id of 1
        And the following tags exist:
        | name                |
        | Fruit of the Spirit |
      When I go to the page for the memverse with the id of 1
      Then I should see "Old Dog"
      When I click inside "td.tag"
      And I sleep for 2
      And I type in "Frui" into autocomplete list "input" and I choose "Fruit of the Spirit"
      Then the tag "Fruit of the Spirit" should exist for memverse #1
      And I should see "Fruit of the Spirit" within "#user-tags"
