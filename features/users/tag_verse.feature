@tag_verse
Feature: Tag Verse
 In order to share thoughts on the verses
 As a user
 I want to tag verse

  Background:
    Given the following verses exist:
      |id | translation | book_index | book    | chapter | versenum | text                                                    |
      | 1 | NIV         | 1          | Genesis | 1       | 1        | In the beginning God created the heavens and the earth  |
    And the following user exists:
	  | name    | email               | password |
      | Old Dog | olddog@test.com     | please   |
    And the following memverses exist:
      | id | User           | Verse |
      | 1  | name: Old Dog  | id: 1 |
    And Old Dog is signed in
    And I go to the page for the memverse with the id of 1

    @javascript
    Scenario: User tags with valid tag
	  I should see "In the beginning God"
	  When I click inside "td.tag"
      And I fill in "td.tag form input" with "Creation"
      And I submit the form
      Then I should see "Creation" within "#user-tags"

    @javascript
    Scenario: User tags with duplicate tag
      Given I have tag: Creation
      When I click inside "td.tag"
	  And I type in "Crea" into autocomplete list "input" and I choose "Creation"
      Then I should get an error

    @javascript
    Scenario: User tags with autocomplete tag
      Given the following tag exists:
        | name     |
        | Creation |
      And I type in "Crea" into autocomplete list "new_tag" and I choose "Creation"
      Then the tag "Creation" should exist for memverse #1
      And I should see "Creation" within "#user-tags"
