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
      | User           | Verse |
      | name: Old Dog  | id: 1 |
    And Old Dog is signed in
    And I go to the page for the memverse with the id of 1
    
    
   @javascript
   Scenario: User tags with valid tag
    When I click "New Tag"
	And I fill in "new tag" with "Creation"
    And I press "enter"
    Then I should see "Creation" in "#user-tags"
    And tag should be inserted at top of user tags
    
   @javascript
   Scenario: User tags with duplicate tag
    Given I have tag: Creation
    When I fill in "td.edit_verse form input" with "Creation"
    And I submit the form
	Then I should get an error
    
   @javascript 
   Scenario: User tags with autocomplete tag
   	Given the following tag exists:
      | name     |
	  | Creation |
   	And I fill in "new_tag" with "cre"
   	Then I should see "Creation"
   	When I click "Creation"
   	Then the tag "Creation" should exist for memverse #1
   	And I should see "Creation" in "#user-tags"
