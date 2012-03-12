@tag_verse
Feature: Tag Verse
 In order to share thoughts on the verses
 As a user
 I want to tag verse
	
  Background:
    Given the following verses exist:
      |id | translation | book_index | book    | chapter | versenum | text                                                    |
      | 1 | NIV         | 1          | Genesis | 1       | 1        | In the beginning God created the heavens and the earth  |
      | 2 | NIV         | 1          | Genesis | 1       | 2        | Now the earth was formless and void                     |
    And the following user exists:
	  | name    | email               | password |
      | Old Dog | olddog@test.com     | please   |
    And the following memverses exist:
      | User           | Verse |
      | name: Old Dog  | id: 1 |
      | name: Old Dog  | id: 2 |
    And Old Dog is signed in
    And I go to the page for the memverse with the id of "1"
    
    
   @javascript
   Scenario: User tags with valid tag
    And I make a tag named "Creation"
    And I press "enter"
    Then tag should be added
    Then tag should be inserted at top of user tags
    
   @javascript
   Scenario: User tags with duplicate tag
    Given I have tag: Creation
    And I fill in the following
     |new tag       |Creation|
    And I press "enter"
    
   @javascript 
   Scenario: User tags with autocomplete tag
   	And there is a tag: Creation
   	And I fill in the following:
   	 |new_tag      |cre|
   	Then I should see dropdown list with salvation
   	Given I see "Creation"
   	And I click "Creation"
   	Then tag should be added
   	Then tag should be inserted at top of user tags
